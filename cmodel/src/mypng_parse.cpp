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

//*** CORE *********************************************************************
void cfgHelp()
{
  cout << endl;
  cout << "--help                      print help information                                           " << endl;
  cout << "--configuration_file / -c   configuration file                                               " << endl;
  cout << endl;
  cout << "--input_file         / -i   input file                                                       " << endl;
  cout << "--output_file        / -o   output file                                                      " << endl;
  cout << "--width              / -w   width of picture                                                 " << endl;
  cout << "--height             / -h   height of picture                                                " << endl;
  cout << "--windowsize         / -s   sliding window size for lz77                                     " << endl;
  cout << "--minmatch           / -m   minimal match size / length for lz77                             " << endl;
  cout << "--nicematch          / -n   nice match size for lz77; stop searching if >= this length found " << endl;
}


void cfgInit(cfg_t *cfg)
{
  cfg->input_file   = "";
  cfg->output_file  = "";
  cfg->width        = 1;
  cfg->height       = 1;
  cfg->windowsize   = 2048;
  cfg->minmatch     = 3;
  cfg->nicematch    = 128;
}

void cfgMap(cfg_t *cfg, string datKey, string datCfg)
{
  // variables
  const char *datCfgStr = datCfg.data();
  int datCfgInt = atoi(datCfgStr);

  // mapping
  if      (datKey == "--input_file " || datKey == "-i") cfg->input_file  = datCfgStr;
  else if (datKey == "--output_file" || datKey == "-o") cfg->output_file = datCfgStr;
  else if (datKey == "--width      " || datKey == "-w") cfg->width       = datCfgInt;
  else if (datKey == "--height     " || datKey == "-h") cfg->height      = datCfgInt;
  else if (datKey == "--windowsize " || datKey == "-s") cfg->windowsize  = datCfgInt;
  else if (datKey == "--minmatch   " || datKey == "-m") cfg->minmatch    = datCfgInt;
  else if (datKey == "--nicematch  " || datKey == "-n") cfg->nicematch   = datCfgInt;
}

unsigned cfgSetFromFile(cfg_t *cfg, int argc, char **argv)
{
  // get config file
  bool flgFile = 0;
  string fileCfg;
  for (int i = 0; i < argc; i++) {
    if (argv[i] == "--configuration_file" || argv[i] == "-c"){
      flgFile = 1;
      fileCfg = argv[i+1];
      break;
    }
  }

  // open config file
  fstream fptCfg;
  if (flgFile) {
    fptCfg.open(fileCfg.c_str());
    if (!fptCfg.is_open()) {
      cout << "ERROR: cannot find configuration file (" << fileCfg << ")" << endl;
      return 1;
    }
    else {
      // process config file
      string datKey, datCfg;
      fptCfg >> datKey;
      while (fptCfg >> datCfg) {
        cfgMap(cfg, datKey, datCfg);
        datKey = datCfg;
      }

      // close config file
      fptCfg.close();
      return 0;
    }
  }
  else {
    return 0;
  }
}

void cfgSetFromCLI(cfg_t *cfg, int argc, char **argv)
{
  for (int i = 1; i < argc - 1; i++)
    cfgMap(cfg, argv[i], argv[i+1]);
}

unsigned cfgChk(cfg_t *cfg)
{
  if (fopen(cfg->input_file.c_str(), "r") == NULL){
    cout << "ERROR: cannot find input file( " << cfg->input_file << ")" << endl;
    return 1;
  }
  if (cfg->width < 1 || cfg->width > 2048){
    cout << "ERROR: width should with [1, 2048]" << endl;
    return 1;
  }
  if (cfg->height < 1 || cfg->height > 1080){
    cout << "ERROR: height should with [1, 1080]" << endl;
    return 1;
  }
  if (cfg->windowsize < 3 || cfg->windowsize > 2048){
    cout << "ERROR: windowsize should with [3, 2048]" << endl;
    return 1;
  }
  if (cfg->minmatch < 3 || cfg->minmatch > 258){
    cout << "ERROR: minmatch should with [3, 258]" << endl;
    return 1;
  }
  if (cfg->nicematch < 1 || cfg->nicematch > 258){
    cout << "ERROR: nicematch should with [3, 258]" << endl;
    return 1;
  }

  return 0;
}

unsigned cfgSet(cfg_t *cfg, int argc, char **argv)
{
  // help
  for (int i = 0; i < argc; i++)
    if (argv[i] == "--help") {
      cfgHelp();
      return 1;
    }

  // initial
  cfgInit(cfg);

  // set from cfg file  
  unsigned datRet;
  if ((datRet = cfgSetFromFile(cfg, argc, argv)))
    return datRet;

  // set from command line interface
  cfgSetFromCLI(cfg, argc, argv);

  // check
  if ((datRet = cfgChk(cfg)))
    return datRet;

  return 0;
}

unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename)
{
  FILE* file;
  file = fopen(filename, "wb" );
  if(!file) return 79;
  fwrite(buffer, 1, buffersize, file);
  fclose(file);
  return 0;
}



void lodepng_setstate_32bitRGBA(cfg_t* cfg, LodePNGState* state)
{
  // init encoding settings
  state->encoder.zlibsettings.btype = 1;         // unchangeable
  state->encoder.zlibsettings.windowsize = 2048; // changeable
  state->encoder.zlibsettings.minmatch = 3;      // changeable
  state->encoder.zlibsettings.nicematch = 128;   // changeable

  state->encoder.filter_strategy = LFS_MINSUM;   // changeable

  // init PNG image info
  state->info_png.width = 1;
  state->info_png.height = 1;
  state->info_png.bitdepth = 8;                  // unchangeable
  state->info_png.colortype = LCT_RGBA;          // unchangeable
  state->info_png.interlace_method = 0;
  state->info_png.compression_method = 0;
  state->info_png.filter_method = 0;

  // set state from cfg
  state->encoder.zlibsettings.windowsize = cfg->windowsize;
  state->encoder.zlibsettings.minmatch   = cfg->minmatch;    
  state->encoder.zlibsettings.nicematch  = cfg->nicematch; 
  state->info_png.width                  = cfg->width;
  state->info_png.height                 = cfg->height;
}

/*The input are command line arguments, the output are setted state and image*/
void lodepng_setstate(cfg_t *cfg, LodePNGState* state)
{
  lodepng_setstate_32bitRGBA(cfg, state);
}
