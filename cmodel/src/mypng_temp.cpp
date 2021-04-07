#include "mypng.hpp"

unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename) {
  FILE* file;
  file = fopen(filename, "wb" );
  if(!file) return 79;
  fwrite(buffer, 1, buffersize, file);
  fclose(file);
  return 0;
}

void lodepng_memcpy(void* __restrict dst, const void* __restrict src, size_t size) {
  size_t i;
  for(i = 0; i < size; i++) ((char*)dst)[i] = ((const char*)src)[i];
}

void lodepng_set32bitInt(unsigned char* buffer, unsigned value) {
  buffer[0] = (unsigned char)((value >> 24) & 0xff);
  buffer[1] = (unsigned char)((value >> 16) & 0xff);
  buffer[2] = (unsigned char)((value >>  8) & 0xff);
  buffer[3] = (unsigned char)((value      ) & 0xff);
}

unsigned lodepng_read32bitInt(const unsigned char* buffer) {
  return (((unsigned)buffer[0] << 24u) | ((unsigned)buffer[1] << 16u) |
         ((unsigned)buffer[2] << 8u) | (unsigned)buffer[3]);
}

//********************************************************
/*dynamic vector of unsigned chars*/
ucvector ucvector_init(unsigned char* buffer, size_t size) {
  ucvector v;
  v.data = buffer;
  v.allocsize = v.size = size;
  return v;
}

unsigned ucvector_resize(ucvector* p, size_t size) {
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
void uivector_init(uivector* p) {
  p->data = NULL;
  p->size = p->allocsize = 0;
}

void uivector_cleanup(void* p) {
  ((uivector*)p)->size = ((uivector*)p)->allocsize = 0;
  free(((uivector*)p)->data);
  ((uivector*)p)->data = NULL;
}

unsigned uivector_resize(uivector* p, size_t size)
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

unsigned uivector_push_back(uivector* p, unsigned c)
{
  uivector_resize(p, p->size + 1);
  p->data[p->size - 1] = c;
  return 1; /*success*/
}

//********************************************************
unsigned lodepng_chunk_init(unsigned char** chunk, ucvector* out, unsigned length, const char* type)
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

//********************************************************
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

//********************************************************
void LodePNGBitWriter_init(LodePNGBitWriter* writer, ucvector* data)
{
  writer->data = data;
  writer->bp = 0;
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

//********************************************************
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

//********************************************************
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
