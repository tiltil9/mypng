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

//*** BIT WRITER ***************************************************************
typedef struct {
  ucvector* data;
  unsigned char bp; /*ok to overflow, indicates bit pos inside byte*/
} LodePNGBitWriter;

void LodePNGBitWriter_init(LodePNGBitWriter* writer, ucvector* data)
{
  writer->data = data;
  writer->bp = 0;
}

#define WRITEBIT(writer, bit){\
  /* append new byte */\
  if(((writer->bp) & 7u) == 0) {\
    ucvector_resize(writer->data, writer->data->size + 1);\
    writer->data->data[writer->data->size - 1] = 0;\
  }\
  (writer->data->data[writer->data->size - 1]) |= (bit << ((writer->bp) & 7u));\
  ++writer->bp;\
}

/* LSB of value is written first, and LSB of bytes is used first */
void writeBits(LodePNGBitWriter* writer, unsigned value, size_t nbits)
{
  if(nbits == 1) { /* compiler should statically compile this case if nbits == 1 */
    WRITEBIT(writer, value);
  }
  else {
    for(size_t i = 0; i != nbits; ++i) {
      WRITEBIT(writer, (unsigned char)((value >> i) & 1));
    }
  }
}

/* This one is to use for adding huffman symbol, the value bits are written MSB first */
void writeBitsReversed(LodePNGBitWriter* writer, unsigned value, size_t nbits)
{
  for(size_t i = 0; i != nbits; ++i) {
    WRITEBIT(writer, (unsigned char)((value >> (nbits - 1u - i)) & 1u));
  }
}

//*** HASH *********************************************************************
typedef struct Hash {
  int* head;             /*hash value to head circular pos - can be outdated if went around window*/
  unsigned short* chain; /*circular pos to prev circular pos*/
  int* val;              /*circular pos to hash value*/
} Hash;

static const size_t MAX_SUPPORTED_DEFLATE_LENGTH = 258;
static const unsigned HASH_NUM_VALUES = 65536;
static const unsigned HASH_BIT_MASK = 65535; /*HASH_NUM_VALUES - 1, but C90 does not like that as initializer*/

unsigned hash_init(Hash* hash, unsigned windowsize)
{
  hash->head = (int*)malloc(sizeof(int) * HASH_NUM_VALUES);
  hash->chain = (unsigned short*)malloc(sizeof(unsigned short) * windowsize);
  hash->val = (int*)malloc(sizeof(int) * windowsize);

  /*initialize hash table*/
  for(unsigned i = 0; i != HASH_NUM_VALUES; ++i) hash->head[i] = -1;
  for(unsigned i = 0; i != windowsize; ++i) hash->chain[i] = i; /*same value as index indicates uninitialized*/
  for(unsigned i = 0; i != windowsize; ++i) hash->val[i] = -1;

  return 0;
}

void hash_cleanup(Hash* hash)
{
  free(hash->head);
  free(hash->val);
  free(hash->chain);
}

unsigned getHash(const unsigned char* data, size_t size, size_t pos)
{
  unsigned result = 0;
  if(pos + 2 < size) {
    result ^= ((unsigned)data[pos + 0] << 0u);
    result ^= ((unsigned)data[pos + 1] << 4u);
    result ^= ((unsigned)data[pos + 2] << 8u);
  }
  else {
    if(pos >= size) return 0;
    size_t amount = size - pos;
    for(size_t i = 0; i != amount; ++i) result ^= ((unsigned)data[pos + i] << (i * 8u));
  }
  return result & HASH_BIT_MASK;
}

void updateHashChain(Hash* hash, size_t wpos, unsigned hashval)
{
  hash->val[wpos] = (int)hashval;
  if(hash->head[hashval] != -1) hash->chain[wpos] = hash->head[hashval];
  hash->head[hashval] = (int)wpos;
}

//*** HUFFMAN TREE *************************************************************
typedef struct HuffmanTree {
  unsigned* codes;    /*the huffman codes (bit patterns representing the symbols)*/
  unsigned* lengths;  /*the lengths of the huffman codes*/
  unsigned maxbitlen; /*maximum number of bits a single code can get*/
  unsigned numcodes;  /*number of symbols in the alphabet = number of codes*/
} HuffmanTree;

void HuffmanTree_init(HuffmanTree* tree)
{
  tree->codes = 0;
  tree->lengths = 0;
}

void HuffmanTree_cleanup(HuffmanTree* tree)
{
  free(tree->codes);
  free(tree->lengths);
}

/*256 literals, the end code, some length codes, and 2 unused codes*/
#define NUM_DEFLATE_CODE_SYMBOLS 288
/*the distance codes have their own symbols, 30 used, 2 unused*/
#define NUM_DISTANCE_SYMBOLS 32

unsigned HuffmanTree_makeFromLengths(HuffmanTree* tree, const unsigned* bitlen, size_t numcodes, unsigned maxbitlen)
{
  tree->lengths = (unsigned*)malloc(numcodes * sizeof(unsigned));
  for(unsigned i = 0; i != numcodes; ++i) tree->lengths[i] = bitlen[i];

  tree->numcodes = (unsigned)numcodes; /*number of symbols*/
  tree->maxbitlen = maxbitlen;

  {
    tree->codes = (unsigned*)malloc(tree->numcodes * sizeof(unsigned));
    unsigned* blcount = (unsigned*)malloc((tree->maxbitlen + 1) * sizeof(unsigned)); // bitlen count of 0 ~ tree->maxbitlen
    unsigned* nextcode = (unsigned*)malloc((tree->maxbitlen + 1) * sizeof(unsigned)); // next code of 0 ~ tree->maxbitlen

    for(unsigned n = 0; n != tree->maxbitlen + 1; n++) blcount[n] = nextcode[n] = 0;

    /*step 1: count number of instances of each code length*/
    for(unsigned bits = 0; bits != tree->numcodes; ++bits) ++blcount[tree->lengths[bits]];
    /*step 2: generate the nextcode values*/
    for(unsigned bits = 1; bits <= tree->maxbitlen; ++bits) {
      nextcode[bits] = (nextcode[bits - 1] + blcount[bits - 1]) << 1u;
    }
    /*step 3: generate all the codes*/
    for(unsigned n = 0; n != tree->numcodes; ++n) {
      if(tree->lengths[n] != 0) {
        tree->codes[n] = nextcode[tree->lengths[n]]++;
        /*remove superfluous bits from the code*/
        tree->codes[n] &= ((1u << tree->lengths[n]) - 1u);
      }
    }

    free(blcount);
    free(nextcode);
  }

  return 0;
}

/*get the literal and length code tree of a deflated block with fixed tree, as per the deflate specification*/
unsigned generateFixedLitLenTree(HuffmanTree* tree)
{
  unsigned* bitlen = (unsigned*)malloc(NUM_DEFLATE_CODE_SYMBOLS * sizeof(unsigned));

  /*288 possible codes: 0-255=literals, 256=endcode, 257-285=lengthcodes, 286-287=unused*/
  for(unsigned i =   0; i <= 143; ++i) bitlen[i] = 8;
  for(unsigned i = 144; i <= 255; ++i) bitlen[i] = 9;
  for(unsigned i = 256; i <= 279; ++i) bitlen[i] = 7;
  for(unsigned i = 280; i <= 287; ++i) bitlen[i] = 8;

  HuffmanTree_makeFromLengths(tree, bitlen, NUM_DEFLATE_CODE_SYMBOLS, 15);

  free(bitlen);
  return 0;
}

/*get the distance code tree of a deflated block with fixed tree, as specified in the deflate specification*/
unsigned generateFixedDistanceTree(HuffmanTree* tree)
{
  unsigned* bitlen = (unsigned*)malloc(NUM_DISTANCE_SYMBOLS * sizeof(unsigned));

  /*there are 32 distance codes, but 30-31 are unused*/
  for(unsigned i = 0; i != NUM_DISTANCE_SYMBOLS; ++i) bitlen[i] = 5;
  HuffmanTree_makeFromLengths(tree, bitlen, NUM_DISTANCE_SYMBOLS, 15);

  free(bitlen);
  return 0;
}

//*** LZ77 TOOL ****************************************************************
#define FIRST_LENGTH_CODE_INDEX 257
/*the base lengths represented by codes 257-285*/
static const unsigned LENGTHBASE[29]
  = {3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59,
     67, 83, 99, 115, 131, 163, 195, 227, 258};
/*the base backwards distances (the bits of distance codes appear after length codes and use their own huffman tree)*/
static const unsigned DISTANCEBASE[30]
  = {1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513,
     769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577};
/*the extra bits used by codes 257-285 (added to base length)*/
static const unsigned LENGTHEXTRA[29]
  = {0, 0, 0, 0, 0, 0, 0,  0,  1,  1,  1,  1,  2,  2,  2,  2,  3,  3,  3,  3,
      4,  4,  4,   4,   5,   5,   5,   5,   0};
/*the extra bits of backwards distances (added to base)*/
static const unsigned DISTANCEEXTRA[30]
  = {0, 0, 0, 0, 1, 1, 2,  2,  3,  3,  4,  4,  5,  5,   6,   6,   7,   7,   8,
       8,    9,    9,   10,   10,   11,   11,   12,    12,    13,    13};

/*search the index in the array, that has the largest value smaller than or equal to the given value,
given array must be sorted (if no value is smaller, it returns the size of the given array)*/
size_t searchCodeIndex(const unsigned* array, size_t array_size, size_t value) {
  /*binary search (only small gain over linear). TODO: use CPU log2 instruction for getting symbols instead*/
  size_t left = 1;
  size_t right = array_size - 1;

  while(left <= right) {
    size_t mid = (left + right) >> 1;
    if(array[mid] >= value) right = mid - 1;
    else left = mid + 1;
  }
  if(left >= array_size || array[left] > value) left--;
  return left;
}

void addLengthDistance(uivector* values, size_t length, size_t distance) {
  unsigned length_code = (unsigned)searchCodeIndex(LENGTHBASE, 29, length);
  unsigned extra_length = (unsigned)(length - LENGTHBASE[length_code]);
  unsigned dist_code = (unsigned)searchCodeIndex(DISTANCEBASE, 30, distance);
  unsigned extra_distance = (unsigned)(distance - DISTANCEBASE[dist_code]);

  size_t pos = values->size;
  uivector_resize(values, values->size + 4);
  values->data[pos + 0] = length_code + FIRST_LENGTH_CODE_INDEX;
  values->data[pos + 1] = extra_length;
  values->data[pos + 2] = dist_code;
  values->data[pos + 3] = extra_distance;
}

/*write the lz77-encoded data, which has lit, len and dist codes, to compressed stream using huffman trees.*/
void writeLZ77data(LodePNGBitWriter* writer, const uivector* lz77_encoded, const HuffmanTree* tree_ll, const HuffmanTree* tree_d)
{
  for(size_t i = 0; i != lz77_encoded->size; ++i) {
    unsigned val = lz77_encoded->data[i];
    writeBitsReversed(writer, tree_ll->codes[val], tree_ll->lengths[val]);

    if(val > 256) /*for a length code, 3 more things have to be added*/ {
      unsigned length_index = val - FIRST_LENGTH_CODE_INDEX;
      unsigned n_length_extra_bits = LENGTHEXTRA[length_index];
      unsigned length_extra_bits = lz77_encoded->data[++i];

      unsigned distance_code = lz77_encoded->data[++i];
      unsigned distance_index = distance_code;
      unsigned n_distance_extra_bits = DISTANCEEXTRA[distance_index];
      unsigned distance_extra_bits = lz77_encoded->data[++i];

      writeBits(writer, length_extra_bits, n_length_extra_bits);

      writeBitsReversed(writer, tree_d->codes[distance_code], tree_d->lengths[distance_code]);
      writeBits(writer, distance_extra_bits, n_distance_extra_bits);
    }
  }
}

//*** CORE *********************************************************************
unsigned adler32(const unsigned char* data, unsigned len)
{
  unsigned adler = 1u;
  unsigned s1 = adler & 0xffffu;
  unsigned s2 = (adler >> 16u) & 0xffffu;

  while(len != 0u) {
    /*at least 5552 sums can be done before the sums overflow, saving a lot of module divisions*/
    unsigned amount = len > 5552u ? 5552u : len;
    len -= amount;
    for(unsigned i = 0; i != amount; ++i) {
      s1 += (*data++);
      s2 += s1;
    }
    s1 %= 65521u;
    s2 %= 65521u;
  }

  return (s2 << 16u) | s1;
}

/*The input are raw bytes, the output is in the form of unsigned integers
with codes representing for example literal bytes, or length/distance pairs.
It uses a hash table technique to let it encode faster. */
void encodeLZ77(uivector* out, Hash* hash, const unsigned char* in, size_t inpos, size_t inposend, unsigned windowsize, unsigned minmatch, unsigned nicematch)
{
  /*for large window lengths, assume the user wants no compression loss. Otherwise, max hash chain length speedup.*/
  unsigned maxchainlength = windowsize >= 8192 ? windowsize : windowsize / 8u;

  for(size_t pos = inpos; pos < inposend; ++pos) {
    size_t wpos = pos & (windowsize - 1); /*position for in 'circular' hash buffers*/
    unsigned hashval = getHash(in, inposend, pos);
    updateHashChain(hash, wpos, hashval);

    //
    unsigned chainlength = 0;
    unsigned hashpos = hash->chain[wpos];
    /*search for the longest string*/
    unsigned prev_offset = 0;

    /*the length and offset found for the current position*/
    unsigned length = 0;
    unsigned offset = 0; /*the offset represents the distance in LZ77 terminology*/

    for(;;) {
      if(chainlength++ >= maxchainlength) break;

      unsigned current_offset = (unsigned)(hashpos <= wpos ? wpos - hashpos : wpos - hashpos + windowsize);
      if(current_offset < prev_offset) break; /*stop when went completely around the circular buffer*/
      prev_offset = current_offset;

      if(current_offset > 0) {
        /*test the next characters*/
        const unsigned char * foreptr = &in[pos];
        const unsigned char * backptr = &in[pos - current_offset];
        const unsigned char * lastptr = &in[inposend < pos + MAX_SUPPORTED_DEFLATE_LENGTH ? inposend : pos + MAX_SUPPORTED_DEFLATE_LENGTH];
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
      /*compensate for the fact that longer offsets have more extra bits, a length of only 3 may be not worth it then*/
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

/*The input are raw bytes, the output is in the form of unsigned integers
with codes representing for example literal bytes, or length/distance pairs.*/
void encodeLZ77Hardware(uivector* out, Hash* hash, const unsigned char* in, size_t inpos, size_t inposend, unsigned windowsize, unsigned minmatch, unsigned nicematch)
{
  // init
  size_t windowPos = inpos;
  size_t inputPos = inpos;
  // iter
  while(inputPos < inposend) {
    // search
    unsigned bestLength = 0;                // less than min
    unsigned bestDistance = windowsize + 1; // greater than max
    // search each point in sliding window (the lastest windowsize points behind currenting input Point)
    for(size_t searchPos = windowPos; searchPos < inputPos; ++searchPos) {
      unsigned searchLength = 0;
      unsigned searchDistance = inputPos - searchPos;

      const unsigned char *backptr = &in[searchPos];
      const unsigned char *foreptr = &in[inputPos];
      const unsigned char *lastptr = &in[inposend < inputPos + nicematch ? inposend : inputPos + nicematch]; // in[inposend] may exceed the memory space of in
      while(foreptr != lastptr && *backptr == *foreptr) {
        ++backptr;
        ++foreptr;
        ++searchLength;
      }
      // update when confronted longer matched strings or closer distance
      if(searchLength > bestLength || (searchLength == bestLength && searchDistance < bestDistance)) {
        bestLength = searchLength;
        bestDistance = searchDistance;
      }
    }
    // output and update inputPos
    if(bestLength < minmatch) {
      uivector_push_back(out, in[inputPos]); // literal one byte
      inputPos = inputPos + 1;
    }
    else {
      addLengthDistance(out, bestLength, bestDistance);
      inputPos = inputPos + bestLength;
    }
    // update windowPos according to sliding window size
    if(inputPos - windowPos > windowsize) {
      windowPos = inputPos - windowsize;
    }
  }
}

/*The input are raw bytes, the output is LZ77-compressed data encoded with fixed Huffman codes*/
void deflateFixed(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const PNGCompressSettings* zlibsettings)
{
  ucvector vout = ucvector_init(*out, *outsize);

  LodePNGBitWriter writer;
  LodePNGBitWriter_init(&writer, &vout);

  Hash hash;
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
    size_t end = (start + blocksize > insize) ? insize : start + blocksize;
    unsigned final = (i == numdeflateblocks - 1);

    unsigned BFINAL = final;
    writeBits(&writer, BFINAL, 1);
    writeBits(&writer, 1, 1); /*first bit of BTYPE*/
    writeBits(&writer, 0, 1); /*second bit of BTYPE*/

    uivector lz77_encoded;
    uivector_init(&lz77_encoded);
    // encodeLZ77(&lz77_encoded, &hash, in, start, end, zlibsettings->windowsize, zlibsettings->minmatch, zlibsettings->nicematch);
    encodeLZ77Hardware(&lz77_encoded, &hash, in, start, end, zlibsettings->windowsize, zlibsettings->minmatch, zlibsettings->nicematch);
    writeLZ77data(&writer, &lz77_encoded, &tree_ll, &tree_d);
    writeBitsReversed(&writer,tree_ll.codes[256], tree_ll.lengths[256]); /*add END code*/
    uivector_cleanup(&lz77_encoded);
  }

  /*cleanup*/
  HuffmanTree_cleanup(&tree_ll);
  HuffmanTree_cleanup(&tree_d);

  hash_cleanup(&hash);

  *out = vout.data;
  *outsize = vout.size;
}

/*The input are raw bytes, the output is non-compressed data*/
void deflateNoCompression(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const PNGCompressSettings* zlibsettings)
{
  // non compressed deflate block data: 1 bit BFINAL,2 bits BTYPE,(5 bits): it jumps to start of next byte,
  //                                    2 bytes LEN, 2 bytes NLEN, LEN bytes literal DATA
  ucvector vout = ucvector_init(*out, *outsize);

  size_t numdeflateblocks = (insize + 65534u) / 65535u;
  unsigned datapos = 0;

  for(size_t i = 0; i != numdeflateblocks; ++i) {
    unsigned BFINAL = (i == numdeflateblocks - 1);
    unsigned BTYPE = 0;
    unsigned LEN = (insize - datapos < 65535u) ? (unsigned)insize - datapos : 65535;
    unsigned NLEN = 65535 - LEN;

    size_t pos = vout.size;
    ucvector_resize(&vout, vout.size + LEN + 5);

    vout.data[pos + 0] = (unsigned char)(BFINAL + ((BTYPE & 1u) << 1u) + ((BTYPE & 2u) << 1u));
    vout.data[pos + 1] = (unsigned char)(LEN & 255);
    vout.data[pos + 2] = (unsigned char)(LEN >> 8u);
    vout.data[pos + 3] = (unsigned char)(NLEN & 255);
    vout.data[pos + 4] = (unsigned char)(NLEN >> 8u);
    memcpy(vout.data + pos + 5, in + datapos, LEN);

    datapos += LEN;
  }

  *out = vout.data;
  *outsize = vout.size;
}

/*The input are raw bytes, the output is the stream of zlib compressed data blocks*/
void deflate(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const PNGCompressSettings* zlibsettings)
{
  if(zlibsettings->btype == 1)
    deflateFixed(out, outsize, in, insize, zlibsettings);
  else
    deflateNoCompression(out, outsize, in, insize, zlibsettings);
}

/*The input are raw bytes, the output is the complete zlib stream*/
void zlibCompress(const cfg_t* cfg, unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const PNGCompressSettings* zlibsettings)
{
  // compress
  unsigned char* dataDeflate = 0;
  size_t dataDeflateSize = 0;
  deflate(&dataDeflate, &dataDeflateSize, in, insize, zlibsettings);

  // zlib data: 1 byte CMF (CM+CINFO), 1 byte FLG, deflate data, 4 byte ADLER32 checksum of the Decompressed data
  *outsize = 1 + 1 + dataDeflateSize + 4;
  *out = (unsigned char*)malloc(*outsize);

  unsigned CMF = 120; // 0b01111000: CM 8, CINFO 7. With CINFO 7, any window size up to 32768 can be used
  unsigned FLEVEL = 0;
  unsigned FDICT = 0;
  unsigned CMFFLG = 256 * CMF + FDICT * 32 + FLEVEL * 64;
  unsigned FCHECK = 31 - CMFFLG % 31;
  CMFFLG += FCHECK;
  unsigned ADLER32 = adler32(in, (unsigned)insize);

  (*out)[0] = (unsigned char)(CMFFLG >> 8);
  (*out)[1] = (unsigned char)(CMFFLG & 255);
  for(size_t i = 0; i < dataDeflateSize; ++i) (*out)[i + 2] = dataDeflate[i];
  set32bitInt(&(*out)[*outsize - 4], ADLER32);

  free(dataDeflate);

  // dump
  if (cfg->dumpAdler32) {
    dumpAdler32(in, insize, ADLER32);
  }
}
