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
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename) {
  FILE* file;
  file = fopen(filename, "wb" );
  if(!file) return 79;
  fwrite(buffer, 1, buffersize, file);
  fclose(file);
  return 0;
}

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

//********************************************************
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

static unsigned uivector_resize(uivector* p, size_t size)
{
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

static unsigned uivector_push_back(uivector* p, unsigned c)
{
  uivector_resize(p, p->size + 1);
  p->data[p->size - 1] = c;
  return 1; /*success*/
}

//********************************************************
static unsigned lodepng_chunk_init(unsigned char** chunk, ucvector* out, unsigned length, const char* type)
{
  size_t pos = out->size;
  ucvector_resize(out, out->size + (4 + 4 + length + 4));
  *chunk = out->data + pos;

  /*1: length*/
  lodepng_set32bitInt(*chunk, length);
  /*2: chunk name (4 letters)*/
  lodepng_memcpy(*chunk + 4, type, 4);

  return 0;
}

/* CRC polynomial: 0xedb88320 */
static unsigned lodepng_crc32_table[256] = {
           0u, 1996959894u, 3993919788u, 2567524794u,  124634137u, 1886057615u, 3915621685u, 2657392035u,
   249268274u, 2044508324u, 3772115230u, 2547177864u,  162941995u, 2125561021u, 3887607047u, 2428444049u,
   498536548u, 1789927666u, 4089016648u, 2227061214u,  450548861u, 1843258603u, 4107580753u, 2211677639u,
   325883990u, 1684777152u, 4251122042u, 2321926636u,  335633487u, 1661365465u, 4195302755u, 2366115317u,
   997073096u, 1281953886u, 3579855332u, 2724688242u, 1006888145u, 1258607687u, 3524101629u, 2768942443u,
   901097722u, 1119000684u, 3686517206u, 2898065728u,  853044451u, 1172266101u, 3705015759u, 2882616665u,
   651767980u, 1373503546u, 3369554304u, 3218104598u,  565507253u, 1454621731u, 3485111705u, 3099436303u,
   671266974u, 1594198024u, 3322730930u, 2970347812u,  795835527u, 1483230225u, 3244367275u, 3060149565u,
  1994146192u,   31158534u, 2563907772u, 4023717930u, 1907459465u,  112637215u, 2680153253u, 3904427059u,
  2013776290u,  251722036u, 2517215374u, 3775830040u, 2137656763u,  141376813u, 2439277719u, 3865271297u,
  1802195444u,  476864866u, 2238001368u, 4066508878u, 1812370925u,  453092731u, 2181625025u, 4111451223u,
  1706088902u,  314042704u, 2344532202u, 4240017532u, 1658658271u,  366619977u, 2362670323u, 4224994405u,
  1303535960u,  984961486u, 2747007092u, 3569037538u, 1256170817u, 1037604311u, 2765210733u, 3554079995u,
  1131014506u,  879679996u, 2909243462u, 3663771856u, 1141124467u,  855842277u, 2852801631u, 3708648649u,
  1342533948u,  654459306u, 3188396048u, 3373015174u, 1466479909u,  544179635u, 3110523913u, 3462522015u,
  1591671054u,  702138776u, 2966460450u, 3352799412u, 1504918807u,  783551873u, 3082640443u, 3233442989u,
  3988292384u, 2596254646u,   62317068u, 1957810842u, 3939845945u, 2647816111u,   81470997u, 1943803523u,
  3814918930u, 2489596804u,  225274430u, 2053790376u, 3826175755u, 2466906013u,  167816743u, 2097651377u,
  4027552580u, 2265490386u,  503444072u, 1762050814u, 4150417245u, 2154129355u,  426522225u, 1852507879u,
  4275313526u, 2312317920u,  282753626u, 1742555852u, 4189708143u, 2394877945u,  397917763u, 1622183637u,
  3604390888u, 2714866558u,  953729732u, 1340076626u, 3518719985u, 2797360999u, 1068828381u, 1219638859u,
  3624741850u, 2936675148u,  906185462u, 1090812512u, 3747672003u, 2825379669u,  829329135u, 1181335161u,
  3412177804u, 3160834842u,  628085408u, 1382605366u, 3423369109u, 3138078467u,  570562233u, 1426400815u,
  3317316542u, 2998733608u,  733239954u, 1555261956u, 3268935591u, 3050360625u,  752459403u, 1541320221u,
  2607071920u, 3965973030u, 1969922972u,   40735498u, 2617837225u, 3943577151u, 1913087877u,   83908371u,
  2512341634u, 3803740692u, 2075208622u,  213261112u, 2463272603u, 3855990285u, 2094854071u,  198958881u,
  2262029012u, 4057260610u, 1759359992u,  534414190u, 2176718541u, 4139329115u, 1873836001u,  414664567u,
  2282248934u, 4279200368u, 1711684554u,  285281116u, 2405801727u, 4167216745u, 1634467795u,  376229701u,
  2685067896u, 3608007406u, 1308918612u,  956543938u, 2808555105u, 3495958263u, 1231636301u, 1047427035u,
  2932959818u, 3654703836u, 1088359270u,  936918000u, 2847714899u, 3736837829u, 1202900863u,  817233897u,
  3183342108u, 3401237130u, 1404277552u,  615818150u, 3134207493u, 3453421203u, 1423857449u,  601450431u,
  3009837614u, 3294710456u, 1567103746u,  711928724u, 3020668471u, 3272380065u, 1510334235u,  755167117u
};

/*Return the CRC of the bytes buf[0..len-1].*/
unsigned lodepng_crc32(const unsigned char* data, size_t length)
{
  unsigned r = 0xffffffffu;
  size_t i;
  for(i = 0; i < length; ++i) {
    r = lodepng_crc32_table[(r ^ data[i]) & 0xffu] ^ (r >> 8u);
  }
  return r ^ 0xffffffffu;
}

void lodepng_chunk_generate_crc(unsigned char* chunk)
{
  unsigned length = lodepng_read32bitInt(&chunk[0]);

  unsigned CRC = lodepng_crc32(&chunk[4], length + 4);
  lodepng_set32bitInt(chunk + 8 + length, CRC);
}

//********************************************************
static unsigned adler32(const unsigned char* data, unsigned len)
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

//********************************************************
typedef struct Hash {
  int* head;             /*hash value to head circular pos - can be outdated if went around window*/
  unsigned short* chain; /*circular pos to prev circular pos*/
  int* val;              /*circular pos to hash value*/
} Hash;

static const size_t MAX_SUPPORTED_DEFLATE_LENGTH = 258;
static const unsigned HASH_NUM_VALUES = 65536;
static const unsigned HASH_BIT_MASK = 65535; /*HASH_NUM_VALUES - 1, but C90 does not like that as initializer*/
static unsigned hash_init(Hash* hash, unsigned windowsize)
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

static void hash_cleanup(Hash* hash)
{
  free(hash->head);
  free(hash->val);
  free(hash->chain);
}

static unsigned getHash(const unsigned char* data, size_t size, size_t pos)
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

static void updateHashChain(Hash* hash, size_t wpos, unsigned hashval)
{
  hash->val[wpos] = (int)hashval;
  if(hash->head[hashval] != -1) hash->chain[wpos] = hash->head[hashval];
  hash->head[hashval] = (int)wpos;
}

//********************************************************
typedef struct {
  ucvector* data;
  unsigned char bp; /*ok to overflow, indicates bit pos inside byte*/
} LodePNGBitWriter;

static void LodePNGBitWriter_init(LodePNGBitWriter* writer, ucvector* data)
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
static void writeBits(LodePNGBitWriter* writer, unsigned value, size_t nbits)
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
static void writeBitsReversed(LodePNGBitWriter* writer, unsigned value, size_t nbits)
{
  for(size_t i = 0; i != nbits; ++i) {
    WRITEBIT(writer, (unsigned char)((value >> (nbits - 1u - i)) & 1u));
  }
}

//********************************************************
typedef struct HuffmanTree {
  unsigned* codes;    /*the huffman codes (bit patterns representing the symbols)*/
  unsigned* lengths;  /*the lengths of the huffman codes*/
  unsigned maxbitlen; /*maximum number of bits a single code can get*/
  unsigned numcodes;  /*number of symbols in the alphabet = number of codes*/
} HuffmanTree;

static void HuffmanTree_init(HuffmanTree* tree)
{
  tree->codes = 0;
  tree->lengths = 0;
}

static void HuffmanTree_cleanup(HuffmanTree* tree)
{
  free(tree->codes);
  free(tree->lengths);
}

/*256 literals, the end code, some length codes, and 2 unused codes*/
#define NUM_DEFLATE_CODE_SYMBOLS 288
/*the distance codes have their own symbols, 30 used, 2 unused*/
#define NUM_DISTANCE_SYMBOLS 32

static unsigned HuffmanTree_makeFromLengths(HuffmanTree* tree, const unsigned* bitlen, size_t numcodes, unsigned maxbitlen)
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
static unsigned generateFixedLitLenTree(HuffmanTree* tree)
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
static unsigned generateFixedDistanceTree(HuffmanTree* tree)
{
  unsigned* bitlen = (unsigned*)malloc(NUM_DISTANCE_SYMBOLS * sizeof(unsigned));

  /*there are 32 distance codes, but 30-31 are unused*/
  for(unsigned i = 0; i != NUM_DISTANCE_SYMBOLS; ++i) bitlen[i] = 5;
  HuffmanTree_makeFromLengths(tree, bitlen, NUM_DISTANCE_SYMBOLS, 15);

  free(bitlen);
  return 0;
}

//********************************************************
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
static size_t searchCodeIndex(const unsigned* array, size_t array_size, size_t value) {
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

static void addLengthDistance(uivector* values, size_t length, size_t distance) {
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
static void writeLZ77data(LodePNGBitWriter* writer, const uivector* lz77_encoded, const HuffmanTree* tree_ll, const HuffmanTree* tree_d)
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

//********************************************************
unsigned lodepng_setstate(LodePNGState* state, unsigned char** image, int argc, char **argv);
unsigned lodepng_setstate_32bitRGBA(LodePNGState* state, unsigned char** image, int argc, char **argv);
unsigned lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state);
unsigned preProcessScanlines(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
unsigned preProcessScanlines32bitRGBA(unsigned char** out, size_t* outsize, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
unsigned filter32bitRGBA(unsigned char* out, const unsigned char* in, unsigned w, unsigned h, LodePNGFilterStrategy strategy);
void filterScanline(unsigned char* out, const unsigned char* scanline, const unsigned char* prevline, size_t length, size_t bytewidth, unsigned char filterType);
unsigned char paethPredictor(short a, short b, short c);
unsigned writeSignature(ucvector* out);
unsigned addChunk_IHDR(ucvector* out, unsigned w, unsigned h, unsigned bitdepth, LodePNGColorType colortype, unsigned interlace_method);
unsigned addChunk_IEND(ucvector* out);
unsigned addChunk_IDAT(ucvector* out, const unsigned char* data, size_t datasize, LodePNGCompressSettings* zlibsettings);
unsigned lodepng_zlib_compress(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);
unsigned lodepng_deflate(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);
unsigned lodepng_deflate_fixed(unsigned char** out, size_t* outsize, const unsigned char* in, size_t insize, const LodePNGCompressSettings* zlibsettings);
unsigned encodeLZ77(uivector* out, Hash* hash, const unsigned char* in, size_t inpos, size_t inposend, unsigned windowsize, unsigned minmatch, unsigned nicematch);

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
