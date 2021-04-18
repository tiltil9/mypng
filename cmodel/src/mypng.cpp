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

/*The input are setted state and image, the output are full PNG stream and its size*/
void lodepng_encode(unsigned char** out, size_t* outsize, const unsigned char* image, LodePNGState* state)
{
  *out = 0;
  *outsize = 0;

  unsigned char* data = 0; // uncompressed version of the IDAT chunk data
  size_t datasize = 0;
  ucvector outv = ucvector_init(NULL, 0);

  // compute scanline filter types
  preProcessScanlines(&data, &datasize, image, state->info_png.width, state->info_png.height, state->encoder.filter_strategy);

  // output all PNG chunks
  {
    writeSignature(&outv);
    addChunk_IHDR(&outv, state->info_png.width, state->info_png.height, state->info_png.bitdepth, state->info_png.colortype, state->info_png.interlace_method);
    addChunk_IDAT(&outv, data, datasize, &state->encoder.zlibsettings); // multiple IDAT chunks must be consecutive
    addChunk_IEND(&outv);
  }

  free(data);
  // instead of cleaning the vector up, give it to the output
  *out = outv.data;
  *outsize = outv.size;
}

//*** MAIN *********************************************************************
int main(int argc, char **argv)
{
  // set config from config file or command line interface
  cfg_t cfg;
  if (cfgSet(&cfg, argc, argv))
    return 1;

  // set state from default and config
  LodePNGState state;
  lodepng_setstate(&cfg, &state);

  // read RGBA
  unsigned char* image = (unsigned char*)malloc(cfg.width * cfg.height * 4);
  FILE *fpt = fopen(cfg.input_file.c_str(), "r");
  char dat [10];
  for(unsigned y = 0; y < cfg.height; y++) {
    for(unsigned x = 0; x < cfg.width; x++) {
      for(unsigned c = 0; c < 4; c++) {
        fgets(dat, 10, fpt);
        image[4 * cfg.width * y + 4 * x + c] = atoi(dat);
      }
    }
  }
  fclose(fpt); 

  // encode RGBA into png
  unsigned char* buffer;
  size_t buffersize;
  lodepng_encode(&buffer, &buffersize, image, &state);

  // write png
  lodepng_save_file(buffer, buffersize, cfg.output_file.c_str());

  free(buffer);
  free(image);
  return 0;
}
