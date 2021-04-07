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

int main(int argc, char **argv)
{
  unsigned char* image;
  LodePNGState state;
  lodepng_setstate(&state, &image, argc, argv);

  /*Encode the image*/
  unsigned char* buffer;
  size_t buffersize;
  lodepng_encode(&buffer, &buffersize, image, &state);

  string png_path = "./pic_png/";
  string png_file = png_path  + argv[1] + ".png";
  lodepng_save_file(buffer, buffersize, png_file.c_str());

  free(buffer);
  free(image);
  return 0;
}

/*The input are command line arguments, the output are setted state and image*/
unsigned lodepng_setstate(LodePNGState* state, unsigned char** image, int argc, char **argv)
{
  return lodepng_setstate_32bitRGBA(state, image, argc, argv);
}

unsigned lodepng_setstate_32bitRGBA(LodePNGState* state, unsigned char** image, int argc, char **argv)
{
  /*read image*/
  // check file
  string rgba_path = "./pic_rgba_anchor/";
  string rgba_file = rgba_path + argv[1] + ".txt";
  if(fopen(rgba_file.c_str(), "r") == NULL) {
    printf("file does not exist\n");
    return -1;
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
  *image = (unsigned char*)malloc(width * height * 4);
  for(unsigned y = 0; y < height; y++) {
    for(unsigned x = 0; x < width; x++) {
      for(unsigned c = 0; c < 4; c++) {
        fgets(dat, 10, fpt);
        (*image)[4 * width * y + 4 * x + c] = atoi(dat);
      }
    }
  }
  fclose(fpt); 


  // init encoding settings
  state->encoder.zlibsettings.btype = 1;         // unchangeable
  state->encoder.zlibsettings.windowsize = 2048; // changeable
  state->encoder.zlibsettings.minmatch = 3;      // changeable
  state->encoder.zlibsettings.nicematch = 128;   // changeable

  state->encoder.filter_strategy = LFS_MINSUM;   // changeable

  // init PNG image info
  state->info_png.width = width;
  state->info_png.height = height;
  state->info_png.bitdepth = 8;                  // unchangeable
  state->info_png.colortype = LCT_RGBA;          // unchangeable
  state->info_png.interlace_method = 0;
  state->info_png.compression_method = 0;
  state->info_png.filter_method = 0;

  return 0;
}

/*The input are setted state and image, the output are full PNG stream and its size*/
void lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state)
{
  /*provide some proper output values if error will happen*/
  *out = 0;
  *outsize = 0;

  unsigned char* data = 0; /*uncompressed version of the IDAT chunk data*/
  size_t datasize = 0;
  ucvector outv = ucvector_init(NULL, 0);

  /* compute scanline filter types */
  preProcessScanlines(&data, &datasize, image, state->info_png.width, state->info_png.height, state->encoder.filter_strategy);

  /* output all PNG chunks */
  {
    /*write signature and chunks*/
    writeSignature(&outv);
    /*IHDR*/
    addChunk_IHDR(&outv, state->info_png.width, state->info_png.height, state->info_png.bitdepth, state->info_png.colortype, state->info_png.interlace_method);
    /*IDAT (multiple IDAT chunks must be consecutive)*/
    addChunk_IDAT(&outv, data, datasize, &state->encoder.zlibsettings);
    addChunk_IEND(&outv);
  }

  free(data);
  /*instead of cleaning the vector up, give it to the output*/
  *out = outv.data;
  *outsize = outv.size;
}

/*The input is image, the output is filtered stream*/
void preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy)
{
  preProcessScanlines32bitRGBA(out, outsize, in, w, h, strategy);
}

void preProcessScanlines32bitRGBA(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy)
{
  unsigned colorChannels = 4; /*RGBA*/
  unsigned bitdepth = 8;
  unsigned bpp = colorChannels * bitdepth;

  *outsize = h + (h * ((w * bpp + 7u) / 8u)); /*image size plus an extra byte per scanline + possible padding bits*/
  *out = (unsigned char*)malloc(*outsize);

  if(bpp < 8 && w * bpp != ((w * bpp + 7u) / 8u) * 8u) {
  }
  else {
    filter32bitRGBA(*out, in, w, h, strategy);
  }
}

void filter32bitRGBA(unsigned char* out, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy)
{
  unsigned colorChannels = 4; /*RGBA*/
  unsigned bitdepth = 8;
  unsigned bpp = colorChannels * bitdepth;
  size_t linebytes = ((size_t)(w / 8u) * bpp) + 1u + ((w & 7u) * bpp + 7u) / 8u - 1u; /*the width of a scanline in bytes, not including the filter type*/
  size_t bytewidth = (bpp + 7u) / 8u; /*bytewidth is used for filtering, is 1 when bpp < 8, number of bytes per pixel otherwise*/

  if(strategy >= LFS_ZERO && strategy <= LFS_FOUR) {
    unsigned char type = (unsigned char)strategy;
    const unsigned char* prevline = 0;
    for(unsigned y = 0; y != h; ++y) {
      size_t inindex = linebytes * y;
      size_t outindex = (1 + linebytes) * y; /*the extra filterbyte added to each row*/
      out[outindex] = type; /*filter type byte*/
      filterScanline(&out[outindex + 1], &in[inindex], prevline, linebytes, bytewidth, type);
      prevline = &in[inindex];
    }
  }
  else if(strategy == LFS_MINSUM) {
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
}

void filterScanline(unsigned char* out, const unsigned char* scanline, const unsigned char* prevline, size_t length, size_t bytewidth, unsigned char filterType)
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

unsigned char paethPredictor(short a, short b, short c)
{
  short pa = ((b - c)         < 0 ? -(b - c)         : (b - c)        );
  short pb = ((a - c)         < 0 ? -(a - c)         : (a - c)        );
  short pc = ((a + b - c - c) < 0 ? -(a + b - c - c) : (a + b - c - c));
  /* return input value associated with smallest of pa, pb, pc (with certain priority if equal) */
  if(pb < pa) { a = b; pa = pb; }
  return (pc < pa) ? c : a;
}

void writeSignature(ucvector* out)
{
  size_t pos = out->size;
  const unsigned char signature[] = {137, 80, 78, 71, 13, 10, 26, 10}; /*8 bytes PNG signature, aka the magic bytes*/
  ucvector_resize(out, out->size + 8);
  lodepng_memcpy(out->data + pos, signature, 8);
}

void addChunk_IHDR(ucvector* out, unsigned w, unsigned h, unsigned bitdepth, LodePNGColorType colortype, unsigned interlace_method)
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
}

void addChunk_IEND(ucvector* out)
{
  unsigned char* chunk;

  lodepng_chunk_init(&chunk, out, 0, "IEND");

  /*3: the data*/
  lodepng_memcpy(chunk + 8, NULL, 0);
  /*4: CRC (of the chunkname characters and the data)*/
  lodepng_chunk_generate_crc(chunk);
}

void addChunk_IDAT(ucvector* out, const unsigned char* data, size_t datasize, LodePNGCompressSettings* zlibsettings)
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

/*The input are raw bytes, the output is the stream of zlib compressed data blocks*/
void lodepng_deflate(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings)
{
  lodepng_deflate_fixed(out, outsize, in, insize, zlibsettings);
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
