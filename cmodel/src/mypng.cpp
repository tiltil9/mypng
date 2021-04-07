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
