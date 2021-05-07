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

//*** CORE *********************************************************************
unsigned char paethPredictor(short a, short b, short c)
{
  short pa = ((b - c)         < 0 ? -(b - c)         : (b - c)        );
  short pb = ((a - c)         < 0 ? -(a - c)         : (a - c)        );
  short pc = ((a + b - c - c) < 0 ? -(a + b - c - c) : (a + b - c - c));
  /* return input value associated with smallest of pa, pb, pc (with certain priority if equal) */
  if(pb < pa) { a = b; pa = pb; }
  return (pc < pa) ? c : a;
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

void filter32bitRGBA(unsigned char* out, const unsigned char* in, unsigned w, unsigned h, PNGFilterStrategy strategy)
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
    /*adaptive filtering:
      There is a heuristic called the minimum sum of absolute differences heuristic, suggested by the PNG standard:
         If the image type is Grayscale or RGB (with or without Alpha), and the bit depth is
         not smaller than 8, then use adaptive filtering heuristic as follows: independently for each row, apply
         all five filters and select the filter that produces the smallest sum of absolute values per row.*/

    const unsigned char* prevline = 0;
    unsigned char* attempt[5]; /*five filtering attempts, one for each filter type*/
    for(unsigned char type = 0; type != 5; ++type) {
      attempt[type] = (unsigned char*)malloc(linebytes);
    }

    for(unsigned y = 0; y != h; ++y) {
      size_t smallest = 0;
      unsigned char bestType = 0;
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

void preProcessScanlines32bitRGBA(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, PNGFilterStrategy strategy)
{
  unsigned colorChannels = 4; /*RGBA*/
  unsigned bitdepth = 8;
  unsigned bpp = colorChannels * bitdepth;

  *outsize = h + (h * ((w * bpp + 7u) / 8u)); /*image size plus an extra byte per scanline + possible padding bits*/
  *out = (unsigned char*)malloc(*outsize);

  if(bpp < 8 && w * bpp != ((w * bpp + 7u) / 8u) * 8u) {
    //
  }
  else {
    filter32bitRGBA(*out, in, w, h, strategy);
  }
}


/*The input is image, the output is filtered stream*/
void preProcessScanlines(const cfg_t* cfg, unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, PNGFilterStrategy strategy)
{
  preProcessScanlines32bitRGBA(out, outsize, in, w, h, strategy);

  // dump
  if (cfg->derivedDumpRGBAData) {
    dumpRGBAData(cfg->fptRGBAData, in, w, h);
  }
  if (cfg->derivedDumpFilteredData) {
    dumpFilteredData(cfg->fptFilteredData, *out, w, h);
  }
  if (cfg->derivedDumpFilteredAdler32Data) {
    dumpFilteredAdler32Data(cfg->fptFilteredAdler32Data, *out, w, h);
  }
}
