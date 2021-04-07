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

using namespace std;

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

//********************************************************
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename);

void lodepng_memcpy(void* __restrict dst, const void* __restrict src, size_t size);

void lodepng_set32bitInt(unsigned char* buffer, unsigned value);

unsigned lodepng_read32bitInt(const unsigned char* buffer);

//********************************************************
/*dynamic vector of unsigned chars*/
typedef struct ucvector {
  unsigned char* data;
  size_t size;      /*used size*/
  size_t allocsize; /*allocated size*/
} ucvector;

ucvector ucvector_init(unsigned char* buffer, size_t size);

unsigned ucvector_resize(ucvector* p, size_t size);

//********************************************************
unsigned lodepng_setstate(LodePNGState* state, unsigned char** image, int argc, char **argv);
void lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state);
void preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
void writeSignature(ucvector* out);
void addChunk_IHDR(ucvector* out, unsigned w, unsigned h, unsigned bitdepth, LodePNGColorType colortype, unsigned interlace_method);
void addChunk_IEND(ucvector* out);
void addChunk_IDAT(ucvector* out, const unsigned char* data, size_t datasize, LodePNGCompressSettings* zlibsettings);
void lodepng_zlib_compress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);

//********************************************************
//static unsigned deflateNoCompression(ucvector* out, const unsigned char* data, size_t datasize) {
//  /*non compressed deflate block data: 1 bit BFINAL,2 bits BTYPE,(5 bits): it jumps to start of next byte,
//  2 bytes LEN, 2 bytes NLEN, LEN bytes literal DATA*/
//
//  size_t i, numdeflateblocks = (datasize + 65534u) / 65535u;
//  unsigned datapos = 0;
//  for(i = 0; i != numdeflateblocks; ++i) {
//    unsigned BFINAL, BTYPE, LEN, NLEN;
//    unsigned char firstbyte;
//    size_t pos = out->size;
//
//    BFINAL = (i == numdeflateblocks - 1);
//    BTYPE = 0;
//
//    LEN = 65535;
//    if(datasize - datapos < 65535u) LEN = (unsigned)datasize - datapos;
//    NLEN = 65535 - LEN;
//
//    if(!ucvector_resize(out, out->size + LEN + 5)) return 83; /*alloc fail*/
//
//    firstbyte = (unsigned char)(BFINAL + ((BTYPE & 1u) << 1u) + ((BTYPE & 2u) << 1u));
//    out->data[pos + 0] = firstbyte;
//    out->data[pos + 1] = (unsigned char)(LEN & 255);
//    out->data[pos + 2] = (unsigned char)(LEN >> 8u);
//    out->data[pos + 3] = (unsigned char)(NLEN & 255);
//    out->data[pos + 4] = (unsigned char)(NLEN >> 8u);
//    lodepng_memcpy(out->data + pos + 5, data + datapos, LEN);
//    datapos += LEN;
//  }
//
//  return 0;
//}

#endif /*__MY_PNG_HPP__*/