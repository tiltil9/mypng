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
// support file structure: signature, IHDR, IDAT, ..., IEND
// support configuration :
//                   IHDR: width, height: max 7680 pixels
//                         bit depth    : 8
//                         color type   : 6(RGBA)
//                         compression  : 0
//                         filter       : 0
//                         interlace    : 0(no interlace)
//             zlib(IDAT): CINFO, CM    : 7(window size max 32768 bytes), 8
//                         FLEVEL, FDICT: 0, 0
//                         BTYPE        : 1(compressed with fixed huffman codes)
//
// lodepng implementation:
//                         state.encoder.zlibsettings.btype = 1;
//                         state.encoder.zlibsettings.lazymatching = 0;
//                         state.encoder.auto_convert = 0;
//                         usezeros = 0;
//
//
#ifndef __MY_PNG_HPP__
#define __MY_PNG_HPP__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cstdlib>
#include <string>
#include <iostream>
#include <fstream>

using namespace std;

//*** ENUM AND STRUCT **********************************************************
typedef enum LodePNGColorType {
  //LCT_GREY = 0,
  //LCT_RGB = 2,
  //LCT_PALETTE = 3,
  //LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6, /*RGB with alpha: 8,16 bit*/
  //LCT_MAX_OCTET_VALUE = 255
} LodePNGColorType;

typedef enum LodePNGFilterStrategy {
  /*every filter at zero*/
  LFS_ZERO = 0,
  /*every filter at 1, 2, 3 or 4 (paeth), unlike LFS_ZERO not a good choice, but for testing*/
  LFS_ONE = 1,
  LFS_TWO = 2,
  LFS_THREE = 3,
  LFS_FOUR = 4,
  /*Use filter that gives minimum sum, as described in the official PNG filter heuristic.*/
  LFS_MINSUM,
  //LFS_ENTROPY,
  //LFS_BRUTE_FORCE,
  //LFS_PREDEFINED
} LodePNGFilterStrategy;

typedef struct LodePNGInfo {
  /*header (IHDR)*/
  unsigned width;
  unsigned height;
  unsigned bitdepth;          /*bits per sample, see PNG standard or documentation further in this header file*/
  LodePNGColorType colortype; /*color type, see PNG standard or documentation further in this header file*/
  unsigned compression_method;/*compression method of the original file. Always 0.*/
  unsigned filter_method;     /*filter method of the original file*/
  unsigned interlace_method;  /*interlace method of the original file: 0=none, 1=Adam7*/
} LodePNGInfo;

typedef struct LodePNGCompressSettings /*deflate = compress*/ {
  unsigned btype;        /*the block type for LZ (0, 1, 2 or 3, see zlib standard). Should be 2 for proper compression.*/
  /*LZ77 related settings*/
  unsigned windowsize;   /*must be a power of two <= 32768. higher compresses more but is slower. Default value: 2048.*/
  unsigned minmatch;     /*minimum lz77 length. 3 is normally best, 6 can be better for some PNGs. Default: 0*/
  unsigned nicematch;    /*stop searching if >= this length found. Set to 258 for best compression. Default: 128*/
} LodePNGCompressSettings;

typedef struct LodePNGEncoderSettings {
  LodePNGCompressSettings zlibsettings; /*settings for the zlib encoder, such as window size, ...*/
  LodePNGFilterStrategy filter_strategy;/*Which filter strategy to use. Default: LFS_MINSUM*/
} LodePNGEncoderSettings;

typedef struct LodePNGState {
  LodePNGEncoderSettings encoder; /*the encoding settings*/
  LodePNGInfo info_png;           /*info of the PNG image obtained after decoding*/
} LodePNGState;

typedef struct cfg_t {
  string   input_file;
  string   output_file;
  unsigned width;
  unsigned height;
  unsigned windowsize;
  unsigned minmatch;
  unsigned nicematch;
  unsigned btype;
} cfg_t;

//*** COMMON TOOL **************************************************************
static void lodepng_memcpy(void* __restrict dst, const void* __restrict src, size_t size) {
  size_t i;
  for(i = 0; i < size; i++) ((char*)dst)[i] = ((const char*)src)[i];
}

static void lodepng_set32bitInt(unsigned char* buffer, unsigned value) {
  buffer[0] = (unsigned char)((value >> 24) & 0xff);
  buffer[1] = (unsigned char)((value >> 16) & 0xff);
  buffer[2] = (unsigned char)((value >>  8) & 0xff);
  buffer[3] = (unsigned char)((value      ) & 0xff);
}

static unsigned lodepng_read32bitInt(const unsigned char* buffer) {
  return (((unsigned)buffer[0] << 24u) | ((unsigned)buffer[1] << 16u) |
         ((unsigned)buffer[2] << 8u) | (unsigned)buffer[3]);
}

//*** DYNAMIC VECTOR ***********************************************************
/*dynamic vector of unsigned chars*/
typedef struct ucvector {
  unsigned char* data;
  size_t size;      /*used size*/
  size_t allocsize; /*allocated size*/
} ucvector;

static ucvector ucvector_init(unsigned char* buffer, size_t size) {
  ucvector v;
  v.data = buffer;
  v.allocsize = v.size = size;
  return v;
}

static unsigned ucvector_resize(ucvector* p, size_t size) {
  if(size > p->allocsize) {
    size_t newsize = size + (p->allocsize >> 1u); // a little larger than size
    void* data = realloc(p->data, newsize);
    if(data) {
      p->allocsize = newsize;
      p->data = (unsigned char*)data;
    }
    else return 0; /*error: not enough memory*/
  }
  p->size = size;
  return 1; /*success*/
}

/*dynamic vector of unsigned ints*/
typedef struct uivector {
  unsigned* data;
  size_t size;      /*size in number of unsigned longs*/
  size_t allocsize; /*allocated size in bytes*/
} uivector;

static void uivector_init(uivector* p) {
  p->data = NULL;
  p->size = p->allocsize = 0;
}

static void uivector_cleanup(void* p) {
  ((uivector*)p)->size = ((uivector*)p)->allocsize = 0;
  free(((uivector*)p)->data);
  ((uivector*)p)->data = NULL;
}

static unsigned uivector_resize(uivector* p, size_t size) {
  size_t allocsize = size * sizeof(unsigned);
  if(allocsize > p->allocsize) {
    size_t newsize = allocsize + (p->allocsize >> 1u);
    void* data = realloc(p->data, newsize);
    if(data) {
      p->allocsize = newsize;
      p->data = (unsigned*)data;
    }
    else return 0; /*error: not enough memory*/
  }
  p->size = size;
  return 1; /*success*/
}

static unsigned uivector_push_back(uivector* p, unsigned c) {
  uivector_resize(p, p->size + 1);
  p->data[p->size - 1] = c;
  return 1; /*success*/
}

//*** INTERFACE FUNCTION DECLARATION *******************************************
// main interface function
unsigned cfgSet(cfg_t* cfg, int argc, char **argv);
void lodepng_setstate(cfg_t* cfg, LodePNGState* state);
void lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state);
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename);
// encode interface function
void preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
void writeSignature(ucvector* out);
void addChunk_IHDR(ucvector* out, unsigned w, unsigned h, unsigned bitdepth, LodePNGColorType colortype, unsigned interlace_method);
void addChunk_IEND(ucvector* out);
void addChunk_IDAT(ucvector* out, const unsigned char* data, size_t datasize, LodePNGCompressSettings* zlibsettings);
// deflate interface function
void lodepng_zlib_compress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);


#endif /*__MY_PNG_HPP__*/