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
  // original image data to filtered data
  unsigned char* dataFiltered = 0;
  size_t dataFilteredSize = 0;
  preProcessScanlines(&dataFiltered, &dataFilteredSize, image, state->info_png.width, state->info_png.height, state->encoder.filter_strategy);

  // filtered data to compressed zlib data
  unsigned char* dataZlib = 0;
  size_t dataZlibSize = 0;
  zlibCompress(&dataZlib, &dataZlibSize, dataFiltered, dataFilteredSize, &state->encoder.zlibsettings);

  // output all PNG chunks
  ucvector outv = ucvector_init(NULL, 0);
  writeSignature(&outv);
  addChunkIHDR(&outv, state->info_png.width, state->info_png.height, state->info_png.bitdepth, state->info_png.colortype, state->info_png.interlace_method);
  addChunkIDAT(&outv, dataZlib, dataZlibSize); // multiple IDAT chunks must be consecutive
  addChunkIEND(&outv);
  // instead of cleaning the vector up, give it to the output
  *out = outv.data;
  *outsize = outv.size;

  free(dataZlib);
  free(dataFiltered);
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
  unsigned char* image = 0;
  readFile(&image, cfg.width, cfg.height, cfg.input_file.c_str());

  // encode RGBA into png
  unsigned char* buffer = 0;
  size_t buffersize = 0;
  lodepng_encode(&buffer, &buffersize, image, &state);

  // print result
  if(0) {
    cout << "Original size: " << (cfg.width * cfg.height * 4) << " bytes, "
         << "Encoded size: "  << (buffersize)                 << " bytes." << endl;
    cout << "Compression ratio: " << (double)(buffersize) / (double)(cfg.width * cfg.height * 4) << endl;
    cout << endl;
  }

  // write png
  saveFile(buffer, buffersize, cfg.output_file.c_str());

  free(buffer);
  free(image);
  return 0;
}
