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
//
#include "mypng.hpp"

int main(int argc, char **argv)
{
  /*read image*/
  // check file
  string rgba_path = "./pic_rgba_anchor/";
  string rgba_file = rgba_path + argv[1] + ".txt";
  if(fopen(rgba_file.c_str(), "r") == NULL){
    printf("file does not exist\n");
    return 0;
  }
  // read width height R G B A...
  FILE *fpt = fopen(rgba_file.c_str(), "r");
  char dat [10];
  // read width
  fgets(dat, 10, fpt);
  unsigned width = atoi(dat);
  // read height
  fgets(dat, 10, fpt);
  unsigned height = atoi(dat);
  // read R G B A...
  unsigned char* image = (unsigned char*)malloc(width * height * 4);
  for(unsigned y = 0; y < height; y++) {
    for(unsigned x = 0; x < width; x++) {
      for(unsigned c = 0; c < 4; c++) {
        fgets(dat, 10, fpt);
        image[4 * width * y + 4 * x + c] = atoi(dat);
      }
    }
  }
  fclose(fpt); 

  /*Encode the image*/
  unsigned char* buffer;
  size_t buffersize;
  lodepng_encode_memory(&buffer, &buffersize, image, width, height, LCT_RGBA, 8);

  
  string png_path = "./pic_png/";
  string png_file = png_path  + argv[1] + ".png";
  lodepng_save_file(buffer, buffersize, png_file.c_str());

  free(buffer);
  free(image);
  return 0;
}

unsigned lodepng_encode_memory(unsigned char** out, size_t* outsize, const unsigned char* image, unsigned w, unsigned h, LodePNGColorType colortype, unsigned bitdepth)
{
  LodePNGState state;
  {
    // init encoding settings
    state.encoder.zlibsettings.btype = 1;         // unchangeable
    state.encoder.zlibsettings.use_lz77 = 1;      // unchangeable
    state.encoder.zlibsettings.windowsize = 2048; // changeable
    state.encoder.zlibsettings.minmatch = 3;      // changeable
    state.encoder.zlibsettings.nicematch = 128;   // changeable
    state.encoder.zlibsettings.lazymatching = 0;  // unchangeable

    state.encoder.filter_strategy = LFS_MINSUM;   // changeable
    state.encoder.auto_convert = 0;               // unchangeable

    // init PNG image info
    state.info_png.color.colortype = LCT_RGBA;    // unchangeable
    state.info_png.color.bitdepth = 8;            // unchangeable

    state.info_png.interlace_method = 0;
    state.info_png.compression_method = 0;
    state.info_png.filter_method = 0;
  }
  state.info_png.color.colortype = colortype;
  state.info_png.color.bitdepth = bitdepth;

  lodepng_encode(out, outsize, image, w, h, &state);

  return 0;
}

unsigned lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, unsigned w, unsigned h, LodePNGState* state)
{
  /*provide some proper output values if error will happen*/
  *out = 0;
  *outsize = 0;

  unsigned char* data = 0; /*uncompressed version of the IDAT chunk data*/
  size_t datasize = 0;
  ucvector outv = ucvector_init(NULL, 0);

  /* compute scanline filter types */
  preProcessScanlines(&data, &datasize, image, w, h, &state->info_png, &state->encoder);

  /* output all PNG chunks */
  {
    /*write signature and chunks*/
    writeSignature(&outv);
    /*IHDR*/
    addChunk_IHDR(&outv, w, h, state->info_png.color.colortype, state->info_png.color.bitdepth, state->info_png.interlace_method);
    /*IDAT (multiple IDAT chunks must be consecutive)*/
    addChunk_IDAT(&outv, data, datasize, &state->encoder.zlibsettings);
    addChunk_IEND(&outv);
  }

  free(data);
  /*instead of cleaning the vector up, give it to the output*/
  *out = outv.data;
  *outsize = outv.size;

  return 0;
}

static unsigned preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in,
                                    unsigned w, unsigned h, const LodePNGInfo* info_png, const LodePNGEncoderSettings* settings)
{
  unsigned bpp = 4 * 8; // getNumColorChannels(info_png->color.colortype) * info_png->color.bitdepth;

  *outsize = h + (h * ((w * bpp + 7u) / 8u)); /*image size plus an extra byte per scanline + possible padding bits*/
  *out = (unsigned char*)malloc(*outsize);

  if(bpp < 8 && w * bpp != ((w * bpp + 7u) / 8u) * 8u) {
  }
  else {
    filter(*out, in, w, h, &info_png->color, settings);
  }

  return 0;
}

static unsigned filter(unsigned char* out, const unsigned char* in, unsigned w, unsigned h, const LodePNGColorMode* color, const LodePNGEncoderSettings* settings)
{
  unsigned bpp = 4 * 8; //getNumColorChannels(color->colortype) * color->bitdepth;
  /*the width of a scanline in bytes, not including the filter type*/
  size_t linebytes = ((size_t)(w / 8u) * bpp) + 1u + ((w & 7u) * bpp + 7u) / 8u - 1u;
  /*bytewidth is used for filtering, is 1 when bpp < 8, number of bytes per pixel otherwise*/
  size_t bytewidth = (bpp + 7u) / 8u;

  if(settings->filter_strategy >= LFS_ZERO && settings->filter_strategy <= LFS_FOUR) {
    unsigned char type = (unsigned char)settings->filter_strategy;
    const unsigned char* prevline = 0;
    for(unsigned y = 0; y != h; ++y) {
      size_t inindex = linebytes * y;
      size_t outindex = (1 + linebytes) * y; /*the extra filterbyte added to each row*/
      out[outindex] = type; /*filter type byte*/
      filterScanline(&out[outindex + 1], &in[inindex], prevline, linebytes, bytewidth, type);
      prevline = &in[inindex];
    }
  }
  else if(settings->filter_strategy == LFS_MINSUM) {
    /*adaptive filtering*/
    /*
    There is a heuristic called the minimum sum of absolute differences heuristic, suggested by the PNG standard:
       If the image type is Grayscale or RGB (with or without Alpha), and the bit depth is
       not smaller than 8, then use adaptive filtering heuristic as follows: independently for each row, apply
       all five filters and select the filter that produces the smallest sum of absolute values per row.
    */
    size_t smallest = 0; // TODO: check if these two stuffs should be moved into y-loop below
    unsigned char bestType = 0;

    const unsigned char* prevline = 0;
    unsigned char* attempt[5]; /*five filtering attempts, one for each filter type*/
    for(unsigned char type = 0; type != 5; ++type) {
      attempt[type] = (unsigned char*)malloc(linebytes);
    }

    for(unsigned y = 0; y != h; ++y) {
      for(unsigned char type = 0; type != 5; ++type) {
        filterScanline(attempt[type], &in[y * linebytes], prevline, linebytes, bytewidth, type);

        size_t sum = 0;
        /*calculate the sum of the result*/
        if(type == 0) {
          for(unsigned x = 0; x != linebytes; ++x) sum += (unsigned char)(attempt[type][x]);
        }
        else {
          for(unsigned x = 0; x != linebytes; ++x) {
            /*For differences, each byte should be treated as signed, values above 127 are negative
            (converted to signed char). Filtertype 0 isn't a difference though, so use unsigned there.
            This means filtertype 0 is almost never chosen, but that is justified.*/
            unsigned char s = attempt[type][x];
            sum += s < 128 ? s : (255U - s); // TODO: find whether this is reasonable
          }
        }

        /*check if this is smallest sum (or if type == 0 it's the first case so always store the values)*/
        if(type == 0 || sum < smallest) {
          bestType = type;
          smallest = sum;
        }
      }

      prevline = &in[y * linebytes];
      /*now fill the out values*/
      out[y * (linebytes + 1)] = bestType; /*the first byte of a scanline will be the filter type*/
      for(unsigned x = 0; x != linebytes; ++x) out[y * (linebytes + 1) + 1 + x] = attempt[bestType][x];

    }

    for(unsigned char type = 0; type != 5; ++type) free(attempt[type]);
  }

  return 0;
}

static void filterScanline(unsigned char* out, const unsigned char* scanline, const unsigned char* prevline, size_t length, size_t bytewidth, unsigned char filterType)
{
  switch(filterType) {
    case 0: /*None*/
      for(size_t i = 0; i != length; ++i) out[i] = scanline[i];
      break;
    case 1: /*Sub*/
      for(size_t i = 0; i != bytewidth; ++i) out[i] = scanline[i];
      for(size_t i = bytewidth; i < length; ++i) out[i] = scanline[i] - scanline[i - bytewidth]; // -1 ~ -255 will be added 256 here, the same below
      break;
    case 2: /*Up*/
      if(prevline) {
        for(size_t i = 0; i != length; ++i) out[i] = scanline[i] - prevline[i];
      }
      else {
        for(size_t i = 0; i != length; ++i) out[i] = scanline[i];
      }
      break;
    case 3: /*Average*/
      if(prevline) {
        for(size_t i = 0; i != bytewidth; ++i) out[i] = scanline[i] - (prevline[i] >> 1);
        for(size_t i = bytewidth; i < length; ++i) out[i] = scanline[i] - ((scanline[i - bytewidth] + prevline[i]) >> 1);
      }
      else {
        for(size_t i = 0; i != bytewidth; ++i) out[i] = scanline[i];
        for(size_t i = bytewidth; i < length; ++i) out[i] = scanline[i] - (scanline[i - bytewidth] >> 1);
      }
      break;
    case 4: /*Paeth*/
      if(prevline) {
        /*paethPredictor(0, prevline[i], 0) is always prevline[i]*/
        for(size_t i = 0; i != bytewidth; ++i) out[i] = (scanline[i] - prevline[i]);
        for(size_t i = bytewidth; i < length; ++i) {
          out[i] = (scanline[i] - paethPredictor(scanline[i - bytewidth], prevline[i], prevline[i - bytewidth]));
        }
      }
      else {
        for(size_t i = 0; i != bytewidth; ++i) out[i] = scanline[i];
        /*paethPredictor(scanline[i - bytewidth], 0, 0) is always scanline[i - bytewidth]*/
        for(size_t i = bytewidth; i < length; ++i) out[i] = (scanline[i] - scanline[i - bytewidth]);
      }
      break;
    default: return; /*invalid filter type given*/
  }
}

static unsigned char paethPredictor(short a, short b, short c)
{
  short pa = ((b - c)         < 0 ? -(b - c)         : (b - c)        );
  short pb = ((a - c)         < 0 ? -(a - c)         : (a - c)        );
  short pc = ((a + b - c - c) < 0 ? -(a + b - c - c) : (a + b - c - c));
  /* return input value associated with smallest of pa, pb, pc (with certain priority if equal) */
  if(pb < pa) { a = b; pa = pb; }
  return (pc < pa) ? c : a;
}

static unsigned writeSignature(ucvector* out)
{
  size_t pos = out->size;
  const unsigned char signature[] = {137, 80, 78, 71, 13, 10, 26, 10}; /*8 bytes PNG signature, aka the magic bytes*/
  ucvector_resize(out, out->size + 8);
  lodepng_memcpy(out->data + pos, signature, 8);
  return 0;
}

static unsigned addChunk_IHDR(ucvector* out, unsigned w, unsigned h, LodePNGColorType colortype, unsigned bitdepth, unsigned interlace_method)
{
  unsigned char *chunk, *data;

  lodepng_chunk_init(&chunk, out, 13, "IHDR");

  data = chunk + 8;
  lodepng_set32bitInt(data + 0, w);   /*width*/
  lodepng_set32bitInt(data + 4, h);   /*height*/
  data[8] = (unsigned char)bitdepth;  /*bit depth*/
  data[9] = (unsigned char)colortype; /*color type*/
  data[10] = 0;                       /*compression method*/
  data[11] = 0;                       /*filter method*/
  data[12] = interlace_method;        /*interlace method*/

  lodepng_chunk_generate_crc(chunk);

  return 0;
}

static unsigned addChunk_IEND(ucvector* out)
{
  unsigned char* chunk;

  lodepng_chunk_init(&chunk, out, 0, "IEND");

  /*3: the data*/
  lodepng_memcpy(chunk + 8, NULL, 0);
  /*4: CRC (of the chunkname characters and the data)*/
  lodepng_chunk_generate_crc(chunk);

  return 0;
}

static unsigned addChunk_IDAT(ucvector* out, const unsigned char* data, size_t datasize, LodePNGCompressSettings* zlibsettings)
{
  unsigned char* zlib = 0;
  size_t zlibsize = 0;
  lodepng_zlib_compress(&zlib, &zlibsize, data, datasize, zlibsettings);

  {
    unsigned char* chunk;

    lodepng_chunk_init(&chunk, out, zlibsize, "IDAT");

    /*3: the data*/
    lodepng_memcpy(chunk + 8, zlib, zlibsize);
    /*4: CRC (of the chunkname characters and the data)*/
    lodepng_chunk_generate_crc(chunk);
  }

  free(zlib);
  return 0;
}

unsigned lodepng_zlib_compress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* settings)
{
  *out = NULL;
  *outsize = 0;

  unsigned char* deflatedata = 0;
  size_t deflatesize = 0;
  lodepng_deflate(&deflatedata, &deflatesize, in, insize, settings);

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
  return 0;
}

unsigned lodepng_deflate(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* settings)
{
  ucvector vout = ucvector_init(*out, *outsize);

  {
    LodePNGBitWriter writer;
    Hash hash;
    LodePNGBitWriter_init(&writer, &vout);
    hash_init(&hash, settings->windowsize);

    size_t blocksize = insize; /*if(settings->btype == 1)*/ 
    size_t numdeflateblocks = (insize + blocksize - 1) / blocksize;
    if(numdeflateblocks == 0) numdeflateblocks = 1;

    for(size_t i = 0; i != numdeflateblocks; ++i) {
      unsigned final = (i == numdeflateblocks - 1);
      size_t start = i * blocksize;
      size_t end = start + blocksize;
      if(end > insize) end = insize;

      deflateFixed(&writer, &hash, in, start, end, settings, final); /*if(settings->btype == 1)*/
    }

    hash_cleanup(&hash);
  }

  *out = vout.data;
  *outsize = vout.size;
  return 0;
}

static unsigned deflateFixed(LodePNGBitWriter* writer, Hash* hash,
                             const unsigned char* data, size_t datapos, size_t dataend,
                             const LodePNGCompressSettings* settings, unsigned final)
{
  HuffmanTree tree_ll; /*tree for literal values and length codes*/
  HuffmanTree tree_d;  /*tree for distance codes*/
  HuffmanTree_init(&tree_ll);
  HuffmanTree_init(&tree_d);
  generateFixedLitLenTree(&tree_ll);
  generateFixedDistanceTree(&tree_d);

  unsigned BFINAL = final;
  writeBits(writer, BFINAL, 1);
  writeBits(writer, 1, 1); /*first bit of BTYPE*/
  writeBits(writer, 0, 1); /*second bit of BTYPE*/

  if(settings->use_lz77) {
    uivector lz77_encoded;
    uivector_init(&lz77_encoded);
    encodeLZ77(&lz77_encoded, hash, data, datapos, dataend,
                settings->windowsize, settings->minmatch, settings->nicematch, settings->lazymatching);
    writeLZ77data(writer, &lz77_encoded, &tree_ll, &tree_d);
    uivector_cleanup(&lz77_encoded);
  }
  else /*no LZ77, but still will be Huffman compressed*/ {
  }
  /*add END code*/
  writeBitsReversed(writer,tree_ll.codes[256], tree_ll.lengths[256]);

  /*cleanup*/
  HuffmanTree_cleanup(&tree_ll);
  HuffmanTree_cleanup(&tree_d);

  return 0;
}

/*
LZ77-encode the data. Return value is error code. The input are raw bytes, the output
is in the form of unsigned integers with codes representing for example literal bytes, or
length/distance pairs.
It uses a hash table technique to let it encode faster. When doing LZ77 encoding, a
sliding window (of windowsize) is used, and all past bytes in that window can be used as
the "dictionary". A brute force search through all possible distances would be slow, and
this hash technique is one out of several ways to speed this up.
*/
static unsigned encodeLZ77(uivector* out, Hash* hash,
                           const unsigned char* in, size_t inpos, size_t inposend, 
                           unsigned windowsize, unsigned minmatch, unsigned nicematch, unsigned lazymatching)
{
  unsigned usezeros = 0; // unchangeable /*not sure if setting it to false for windowsize < 8192 is better or worse*/
  unsigned numzeros = 0;
  /*for large window lengths, assume the user wants no compression loss. Otherwise, max hash chain length speedup.*/
  unsigned maxchainlength = windowsize >= 8192 ? windowsize : windowsize / 8u;

  for(size_t pos = inpos; pos < inposend; ++pos) {
    size_t wpos = pos & (windowsize - 1); /*position for in 'circular' hash buffers*/

    unsigned hashval = getHash(in, inposend, pos);

    if(usezeros && hashval == 0) {
      //if(numzeros == 0)
      //  numzeros = countZeros(in, inposend, pos);
      //else if(pos + numzeros > inposend || in[pos + numzeros - 1] != 0)
      //  --numzeros;
    }
    else {
      numzeros = 0;
    }

    updateHashChain(hash, wpos, hashval, numzeros);


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

        /*common case in PNGs is lots of zeros. Quickly skip over them as a speedup*/
        if(numzeros >= 3) {
          //unsigned skip = hash->zeros[hashpos];
          //if(skip > numzeros) skip = numzeros;
          //backptr += skip;
          //foreptr += skip;
        }

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
      if(numzeros >= 3 && length > numzeros) {
        //hashpos = hash->chainz[hashpos];
        //if(hash->zeros[hashpos] != numzeros) break;
      }
      else {
        hashpos = hash->chain[hashpos];
        /*outdated hash value, happens if particular value was not encountered in whole last window*/
        if(hash->val[hashpos] != (int)hashval) break;
      }
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
        if(usezeros && hashval == 0) {
          //if(numzeros == 0)
          //  numzeros = countZeros(in, inposend, pos);
          //else if(pos + numzeros > inposend || in[pos + numzeros - 1] != 0)
          //  --numzeros;
        }
        else {
          numzeros = 0;
        }
        updateHashChain(hash, wpos, hashval, numzeros);
      }
    }
  } /*end of the loop through each character of input*/

  return 0;
}
