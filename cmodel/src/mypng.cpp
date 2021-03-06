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
  PNGState state;
  setState(cfg, &state);

  // read RGBA
  unsigned char* image = 0;
  readFile(&image, cfg->width, cfg->height, cfg->input_file.c_str());

  // original image data to filtered data
  unsigned char* dataFiltered = 0;
  size_t dataFilteredSize = 0;
  preProcessScanlines(cfg, &dataFiltered, &dataFilteredSize, image, state.info_png.width, state.info_png.height, state.encoder.filter_strategy);
  free(image);

  // filtered data to compressed zlib data
  unsigned char* dataZlib = 0;
  size_t dataZlibSize = 0;
  zlibCompress(cfg, &dataZlib, &dataZlibSize, dataFiltered, dataFilteredSize, &state.encoder.zlibsettings);
  free(dataFiltered);

  // output all PNG chunks stream
  unsigned char* buffer = 0;
  size_t bufferSize = 0;
  pngPackage(cfg, &buffer, &bufferSize, dataZlib, dataZlibSize, &state.info_png);
  free(dataZlib);

  // print encode result
  if(cfg->dumpLog) {
    cout << " Original RGBA size: "    << setw(8)                  << (cfg->width * cfg->height * 4)                                      << " bytes" << endl;
    cout << " Encoded  PNG  size: "    << setw(8)                  << (bufferSize)                                                        << " bytes" << endl;
    cout << " --> Compression ratio: " << fixed << setprecision(2) << (double)(bufferSize) / (double)(cfg->width * cfg->height * 4) * 100 << "%"      << endl;
    cout << endl;
  }

  // write PNG
  saveFile(buffer, bufferSize, cfg->output_file.c_str());
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
