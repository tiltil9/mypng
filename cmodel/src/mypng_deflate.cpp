/******************************************************************************
*******************************************************************************
**                                                                           **
**  File        :
**  Contributor :
**  Date        :
**  Description :
**                                                                           **
*******************************************************************************
******************************************************************************/
#include "mypng.hpp"

/*The input are raw bytes, the output is in the form of unsigned integers
with codes representing for example literal bytes, or length/distance pairs.
It uses a hash table technique to let it encode faster. */
void encodeLZ77(uivector* out, Hash* hash, const unsigned char* in, size_t inpos, size_t inposend, unsigned windowsize, unsigned minmatch, unsigned nicematch)
{
  //unsigned usezeros = 0;     // unchangeable
  //unsigned lazymatching = 0; // unchangeable
  /*for large window lengths, assume the user wants no compression loss. Otherwise, max hash chain length speedup.*/
  unsigned maxchainlength = windowsize >= 8192 ? windowsize : windowsize / 8u;

  for(size_t pos = inpos; pos < inposend; ++pos) {
    size_t wpos = pos & (windowsize - 1); /*position for in 'circular' hash buffers*/
    unsigned hashval = getHash(in, inposend, pos);
    updateHashChain(hash, wpos, hashval);


    const unsigned char * lastptr = &in[inposend < pos + MAX_SUPPORTED_DEFLATE_LENGTH ? inposend : pos + MAX_SUPPORTED_DEFLATE_LENGTH];

    unsigned chainlength = 0;
    unsigned hashpos = hash->chain[wpos];

    /*the length and offset found for the current position*/
    unsigned length = 0;
    unsigned offset = 0; /*the offset represents the distance in LZ77 terminology*/

    /*search for the longest string*/
    unsigned prev_offset = 0;

    for(;;) {
      if(chainlength++ >= maxchainlength) break;
      unsigned current_offset = (unsigned)(hashpos <= wpos ? wpos - hashpos : wpos - hashpos + windowsize);

      if(current_offset < prev_offset) break; /*stop when went completely around the circular buffer*/
      prev_offset = current_offset;

      if(current_offset > 0) {
        /*test the next characters*/
        const unsigned char * foreptr = &in[pos];
        const unsigned char * backptr = &in[pos - current_offset];

        while(foreptr != lastptr && *backptr == *foreptr) /*maximum supported length by deflate is max length*/ {
          ++backptr;
          ++foreptr;
        }
        unsigned current_length = (unsigned)(foreptr - &in[pos]);

        if(current_length > length) {
          length = current_length; /*the longest length*/
          offset = current_offset; /*the offset that is related to this longest length*/
          /*jump out once a length of max length is found (speed gain). This also jumps
          out if length is MAX_SUPPORTED_DEFLATE_LENGTH*/
          if(current_length >= nicematch) break;
        }
      }

      if(hashpos == hash->chain[hashpos]) break;
      hashpos = hash->chain[hashpos];
      /*outdated hash value, happens if particular value was not encountered in whole last window*/
      if(hash->val[hashpos] != (int)hashval) break;
    }

    /*encode it as length/distance pair or literal value*/
    if(length < 3) /*only lengths of 3 or higher are supported as length/distance pair*/ {
      uivector_push_back(out, in[pos]);
    }
    else if(length < minmatch || (length == 3 && offset > 4096)) {
      /*compensate for the fact that longer offsets have more extra bits, a
      length of only 3 may be not worth it then*/
      uivector_push_back(out, in[pos]);
    }
    else {
      addLengthDistance(out, length, offset);
      for(unsigned i = 1; i < length; ++i) {
        ++pos;
        wpos = pos & (windowsize - 1);
        hashval = getHash(in, inposend, pos);
        updateHashChain(hash, wpos, hashval);
      }
    }
  } /*end of the loop through each character of input*/
}

/*The input are raw bytes, the output is LZ77-compressed data encoded with fixed Huffman codes*/
void lodepng_deflate_fixed(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings)
{
  //zlibsettings->btype = 1;
  ucvector vout = ucvector_init(*out, *outsize);

  LodePNGBitWriter writer;
  Hash hash;
  LodePNGBitWriter_init(&writer, &vout);
  hash_init(&hash, zlibsettings->windowsize);

  HuffmanTree tree_ll; /*tree for literal values and length codes*/
  HuffmanTree tree_d;  /*tree for distance codes*/
  HuffmanTree_init(&tree_ll);
  HuffmanTree_init(&tree_d);
  generateFixedLitLenTree(&tree_ll);
  generateFixedDistanceTree(&tree_d);

  size_t blocksize = insize;
  size_t numdeflateblocks = (insize + blocksize - 1) / blocksize;
  if(numdeflateblocks == 0) numdeflateblocks = 1;

  for(size_t i = 0; i != numdeflateblocks; ++i) {
    size_t start = i * blocksize;
    size_t end = start + blocksize;
    if(end > insize) end = insize;
    unsigned final = (i == numdeflateblocks - 1);

    unsigned BFINAL = final;
    writeBits(&writer, BFINAL, 1);
    writeBits(&writer, 1, 1); /*first bit of BTYPE*/
    writeBits(&writer, 0, 1); /*second bit of BTYPE*/

    uivector lz77_encoded;
    uivector_init(&lz77_encoded);
    encodeLZ77(&lz77_encoded, &hash, in, start, end, zlibsettings->windowsize, zlibsettings->minmatch, zlibsettings->nicematch);
    writeLZ77data(&writer, &lz77_encoded, &tree_ll, &tree_d);
    uivector_cleanup(&lz77_encoded);
    /*add END code*/
    writeBitsReversed(&writer,tree_ll.codes[256], tree_ll.lengths[256]);
  }

  /*cleanup*/
  HuffmanTree_cleanup(&tree_ll);
  HuffmanTree_cleanup(&tree_d);

  hash_cleanup(&hash);

  *out = vout.data;
  *outsize = vout.size;
}

/*The input are raw bytes, the output is the stream of zlib compressed data blocks*/
void lodepng_deflate(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings)
{
  lodepng_deflate_fixed(out, outsize, in, insize, zlibsettings);
}

/*The input are raw bytes, the output is the complete zlib stream*/
void lodepng_zlib_compress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings)
{
  *out = NULL;
  *outsize = 0;

  unsigned char* deflatedata = 0;
  size_t deflatesize = 0;
  lodepng_deflate(&deflatedata, &deflatesize, in, insize, zlibsettings);

  *outsize = 1 + 1 + deflatesize + 4;
  *out = (unsigned char*)malloc(*outsize);

  {
    /*zlib data: 1 byte CMF (CM+CINFO), 1 byte FLG, deflate data, 4 byte ADLER32 checksum of the Decompressed data*/
    unsigned CMF = 120; /*0b01111000: CM 8, CINFO 7. With CINFO 7, any window size up to 32768 can be used.*/
    unsigned FLEVEL = 0;
    unsigned FDICT = 0;
    unsigned CMFFLG = 256 * CMF + FDICT * 32 + FLEVEL * 64;
    unsigned FCHECK = 31 - CMFFLG % 31;
    CMFFLG += FCHECK;
    unsigned ADLER32 = adler32(in, (unsigned)insize);

    (*out)[0] = (unsigned char)(CMFFLG >> 8);
    (*out)[1] = (unsigned char)(CMFFLG & 255);
    for(size_t i = 0; i != deflatesize; ++i) (*out)[i + 2] = deflatedata[i];
    lodepng_set32bitInt(&(*out)[*outsize - 4], ADLER32);
  }

  free(deflatedata);
}
