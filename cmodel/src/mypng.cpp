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

//*** ONE SHOT *****************************************************************
void oneShot(const cfg_t* cfg)
{
  // set state from default and config
  LodePNGState state;
  setState(cfg, &state);

  // read RGBA
  unsigned char* image = 0;
  readFile(&image, cfg->width, cfg->height, cfg->input_file.c_str());

  // original image data to filtered data
  unsigned char* dataFiltered = 0;
  size_t dataFilteredSize = 0;
  preProcessScanlines(&dataFiltered, &dataFilteredSize, image, state.info_png.width, state.info_png.height, state.encoder.filter_strategy);
  free(image);

  // filtered data to compressed zlib data
  unsigned char* dataZlib = 0;
  size_t dataZlibSize = 0;
  zlibCompress(&dataZlib, &dataZlibSize, dataFiltered, dataFilteredSize, &state.encoder.zlibsettings);
  free(dataFiltered);

  // output all PNG chunks stream
  unsigned char* buffer = 0;
  size_t buffersize = 0;
  ucvector outv = ucvector_init(NULL, 0);
  writeSignature(&outv);
  addChunkIHDR(&outv, state.info_png.width, state.info_png.height, state.info_png.bitdepth, state.info_png.colortype, state.info_png.interlace_method);
  addChunkIDAT(&outv, dataZlib, dataZlibSize); // multiple IDAT chunks must be consecutive
  addChunkIEND(&outv);
  buffer = outv.data;
  buffersize = outv.size;
  free(dataZlib);

  // print encode result
  if(0) {
    cout << "Original size: " << (cfg->width * cfg->height * 4) << " bytes, "
         << "Encoded size: "  << (buffersize)                 << " bytes." << endl;
    cout << "Compression ratio: " << (double)(buffersize) / (double)(cfg->width * cfg->height * 4) << endl;
    cout << endl;
  }

  // write PNG
  saveFile(buffer, buffersize, cfg->output_file.c_str());
  free(buffer);
}

//*** MAIN *********************************************************************
int main(int argc, char **argv)
{
  // set config from config file or command line interface
  cfg_t cfg;
  if (cfgSet(&cfg, argc, argv))
    return 1;

  // one shot by config
  oneShot(&cfg);

  return 0;
}
