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

//********************************************************


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

/*The input are command line arguments, the output are setted state and image*/
unsigned lodepng_setstate(LodePNGState* state, unsigned char** image, int argc, char **argv)
{
  return lodepng_setstate_32bitRGBA(state, image, argc, argv);
}
