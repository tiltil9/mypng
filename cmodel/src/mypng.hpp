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

#include <string.h>
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
  LCT_RGBA = 6
} LodePNGColorType;

typedef enum LodePNGFilterStrategy {
  LFS_ZERO = 0,
  LFS_ONE = 1,
  LFS_TWO = 2,
  LFS_THREE = 3,
  LFS_FOUR = 4,
  LFS_MINSUM // Use filter that gives minimum sum, as described in the official PNG filter heuristic
} LodePNGFilterStrategy;

typedef struct LodePNGInfo {
  /*header (IHDR)*/
  unsigned width;
  unsigned height;
  unsigned bitdepth;           // bits per sample, see PNG standard
  LodePNGColorType colortype;  // color type
  unsigned compression_method; // compression method of the original file
  unsigned filter_method;      // filter method of the original file
  unsigned interlace_method;   // interlace method of the original file: 0 = none, 1 = Adam7
} LodePNGInfo;

typedef struct LodePNGCompressSettings {
  unsigned btype;      // the block type for LZ (0, 1, 2 or 3, see zlib standard). Should be 2 for proper compression
  /*LZ77 related settings*/
  unsigned windowsize; // must be a power of two <= 32768. higher compresses more but is slower. Default value: 2048
  unsigned minmatch;   // minimum lz77 length. 3 is normally best, 6 can be better for some PNGs. Default: 3
  unsigned nicematch;  // stop searching if >= this length found. Set to 258 for best compression. Default: 128
} LodePNGCompressSettings;

typedef struct LodePNGEncoderSettings {
  LodePNGCompressSettings zlibsettings;  // settings for the zlib encoder
  LodePNGFilterStrategy filter_strategy; // Which filter strategy to use. Default: LFS_MINSUM
} LodePNGEncoderSettings;

typedef struct LodePNGState {
  LodePNGEncoderSettings encoder; // the encoding settings
  LodePNGInfo info_png;           // info of the PNG image obtained after decoding
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
static void set32bitInt(unsigned char* buffer, unsigned value) {
  buffer[0] = (unsigned char)((value >> 24) & 0xff);
  buffer[1] = (unsigned char)((value >> 16) & 0xff);
  buffer[2] = (unsigned char)((value >>  8) & 0xff);
  buffer[3] = (unsigned char)((value      ) & 0xff);
}

//*** DYNAMIC VECTOR ***********************************************************
/*dynamic vector of unsigned chars*/
typedef struct ucvector {
  unsigned char* data;
  size_t size;      // used size
  size_t allocsize; // allocated size
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
  size_t size;      // size in number of unsigned longs
  size_t allocsize; // allocated size in bytes
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
unsigned readFile(unsigned char** image, unsigned w, unsigned h, const char* fileName);
void lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state);
unsigned saveFile(const unsigned char* buffer, size_t bufferSize, const char* fileName);
// encode interface function
void preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
void zlibCompress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);
// chunk interface function
void writeSignature(ucvector* out);
void addChunkIHDR(ucvector* out, unsigned w, unsigned h, unsigned bitDepth, LodePNGColorType colorType, unsigned interlaceMethod);
void addChunkIEND(ucvector* out);
void addChunkIDAT(ucvector* out, const unsigned char* dataZlib, size_t dataZlibSize);
// dump interface function
void dumpAdler32(const unsigned char* in, size_t insize, unsigned adler32);


#endif /*__MY_PNG_HPP__*/