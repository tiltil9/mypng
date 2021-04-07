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

unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename) {
  FILE* file;
  file = fopen(filename, "wb" );
  if(!file) return 79;
  fwrite(buffer, 1, buffersize, file);
  fclose(file);
  return 0;
}