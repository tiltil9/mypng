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
