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

//*** FILE I/O *****************************************************************
unsigned readFile(unsigned char** image, unsigned w, unsigned h, const char* fileName)
{
  *image = (unsigned char*)malloc(w * h * 4);
  FILE *fpt = fopen(fileName, "r");
  for(unsigned y = 0; y < h; y++) {
    for(unsigned x = 0; x < w; x++) {
      for(unsigned c = 0; c < 4; c++) {
        char dat[10];
        fgets(dat, 10, fpt);
        (*image)[4 * w * y + 4 * x + c] = atoi(dat);
      }
    }
  }
  fclose(fpt);
  return 0;
}

unsigned saveFile(const unsigned char* buffer, size_t bufferSize, const char* fileName)
{
  FILE* fpt = fopen(fileName, "wb");
  if(!fpt) return 1;
  fwrite(buffer, 1, bufferSize, fpt);
  fclose(fpt);
  return 0;
}

//*** CONFIG *******************************************************************
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
  cout << "--btype              / -b   the block type for lz77                                          " << endl;
  cout << "--dumpLog                   dump log knob                                                    " << endl;
  cout << "--dumpFilter                dump file knob for filter simulation                             " << endl;
  cout << "--dumpLz77                  dump file knob for Lz77 simulation                               " << endl;
  cout << "--dumpAdler32               dump file knob for Adler32 simulation                            " << endl;
  cout << "--dumpCrc32                 dump file knob for Crc32 simulation                              " << endl;
  cout << "--dumpBs                    dump file knob for Bs simulation                                 " << endl;
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
  cfg->btype        = 1;
  cfg->dumpLog      = 0;
  cfg->dumpFilter   = 0;
  cfg->dumpLz77     = 0;
  cfg->dumpAdler32  = 0;
  cfg->dumpCrc32    = 0;
  cfg->dumpBs       = 0;
  
  cfg->fptWhData       = NULL;
  cfg->fptRGBAData     = NULL;
  cfg->fptFilteredData = NULL;
  cfg->fptFilteredAdler32Data = NULL;
  cfg->fptAdler32Data  = NULL;
  cfg->fptLz77Data     = NULL;
  cfg->fptZlibData     = NULL;
  cfg->fptZlibBsData   = NULL;
  cfg->fptCrc32Data    = NULL;
}

void cfgMap(cfg_t *cfg, string datKey, string datCfg)
{
  // variables
  const char *datCfgStr = datCfg.data();
  int datCfgInt = atoi(datCfgStr);
  bool datCfgBool = datCfgInt ? true : false;

  // mapping
  if      (datKey == "--input_file"  || datKey == "-i") cfg->input_file  = datCfgStr;
  else if (datKey == "--output_file" || datKey == "-o") cfg->output_file = datCfgStr;
  else if (datKey == "--width"       || datKey == "-w") cfg->width       = datCfgInt;
  else if (datKey == "--height"      || datKey == "-h") cfg->height      = datCfgInt;
  else if (datKey == "--windowsize"  || datKey == "-s") cfg->windowsize  = datCfgInt;
  else if (datKey == "--minmatch"    || datKey == "-m") cfg->minmatch    = datCfgInt;
  else if (datKey == "--nicematch"   || datKey == "-n") cfg->nicematch   = datCfgInt;
  else if (datKey == "--btype"       || datKey == "-b") cfg->btype       = datCfgInt;
  else if (datKey == "--dumpLog"                      ) cfg->dumpLog     = datCfgBool;
  else if (datKey == "--dumpFilter"                   ) cfg->dumpFilter  = datCfgBool;
  else if (datKey == "--dumpLz77"                     ) cfg->dumpLz77    = datCfgBool;
  else if (datKey == "--dumpAdler32"                  ) cfg->dumpAdler32 = datCfgBool;
  else if (datKey == "--dumpCrc32"                    ) cfg->dumpCrc32   = datCfgBool;
  else if (datKey == "--dumpBs"                       ) cfg->dumpBs      = datCfgBool;
}

unsigned cfgSetFromFile(cfg_t *cfg, int argc, char **argv)
{
  // get config file
  bool flgFile = 0;
  string fileCfg;
  for (int i = 1; i < argc; i++) {
    string datKey = argv[i];
    if (datKey == "--configuration_file" || datKey == "-c"){
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
  if (cfg->nicematch < 3 || cfg->nicematch > 258){
    cout << "ERROR: nicematch should with [3, 258]" << endl;
    return 1;
  }
  if (cfg->btype < 0 || cfg->btype > 1){
    cout << "ERROR: btype should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpLog < 0 || cfg->dumpLog > 1){
    cout << "ERROR: dumpLog should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpFilter < 0 || cfg->dumpFilter > 1){
    cout << "ERROR: dumpFilter should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpLz77 < 0 || cfg->dumpLz77 > 1){
    cout << "ERROR: dumpLz77 should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpAdler32 < 0 || cfg->dumpAdler32 > 1){
    cout << "ERROR: dumpAdler32 should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpCrc32 < 0 || cfg->dumpCrc32 > 1){
    cout << "ERROR: dumpCrc32 should with [0, 1]" << endl;
    return 1;
  }
  if (cfg->dumpBs < 0 || cfg->dumpBs > 1){
    cout << "ERROR: dumpBs should with [0, 1]" << endl;
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

  // derive dump
  cfg->derivedDumpRGBAData            = cfg->dumpFilter                   ;
  cfg->derivedDumpFilteredData        = cfg->dumpFilter  || cfg->dumpLz77 ;
  cfg->derivedDumpLz77Data            = cfg->dumpLz77    || cfg->dumpBs   ;
  cfg->derivedDumpFilteredAdler32Data = cfg->dumpAdler32                  ;
  cfg->derivedDumpAdler32Data         = cfg->dumpAdler32 || cfg->dumpBs   ;
  cfg->derivedDumpZlibData            = cfg->dumpCrc32                    ;
  cfg->derivedDumpZlibBsData          = cfg->dumpBs                       ;
  cfg->derivedDumpWhData              = cfg->dumpCrc32                    ;
  cfg->derivedDumpCrc32Data           = cfg->dumpCrc32   || cfg->dumpBs   ;

  // open dump file
  if (cfg->derivedDumpRGBAData           ) cfg->fptRGBAData            = fopen("./check_data/RGBA.dat"            , "w");
  if (cfg->derivedDumpFilteredData       ) cfg->fptFilteredData        = fopen("./check_data/Filtered.dat"        , "w");
  if (cfg->derivedDumpLz77Data           ) cfg->fptLz77Data            = fopen("./check_data/Lz77.dat"            , "w");
  if (cfg->derivedDumpFilteredAdler32Data) cfg->fptFilteredAdler32Data = fopen("./check_data/FilteredAdler32.dat" , "w");
  if (cfg->derivedDumpAdler32Data        ) cfg->fptAdler32Data         = fopen("./check_data/Adler32.dat"         , "w");
  if (cfg->derivedDumpZlibData           ) cfg->fptZlibData            = fopen("./check_data/Zlib.dat"            , "w");
  if (cfg->derivedDumpZlibBsData         ) cfg->fptZlibBsData          = fopen("./check_data/ZlibBs.dat"          , "w");
  if (cfg->derivedDumpWhData             ) cfg->fptWhData              = fopen("./check_data/Wh.dat"              , "w");
  if (cfg->derivedDumpCrc32Data          ) cfg->fptCrc32Data           = fopen("./check_data/Crc32.dat"           , "w");

  return 0;
}

//*** STATE ********************************************************************
void setState32bitRGBA(const cfg_t* cfg, PNGState* state)
{
  // init encoding settings
  state->encoder.zlibsettings.btype = 1;
  state->encoder.zlibsettings.windowsize = 2048;
  state->encoder.zlibsettings.minmatch = 3;
  state->encoder.zlibsettings.nicematch = 128;

  state->encoder.filter_strategy = LFS_MINSUM;

  // init PNG image info
  state->info_png.width = 1;
  state->info_png.height = 1;
  state->info_png.bitdepth = 8;                  // unchangeable
  state->info_png.colortype = LCT_RGBA;          // unchangeable
  state->info_png.interlace_method = 0;
  state->info_png.compression_method = 0;
  state->info_png.filter_method = 0;

  // set state from cfg
  state->info_png.width                  = cfg->width;
  state->info_png.height                 = cfg->height;
  state->encoder.zlibsettings.windowsize = cfg->windowsize;
  state->encoder.zlibsettings.minmatch   = cfg->minmatch;    
  state->encoder.zlibsettings.nicematch  = cfg->nicematch; 
  state->encoder.zlibsettings.btype      = cfg->btype;
}

void setState(const cfg_t* cfg, PNGState* state)
{
  setState32bitRGBA(cfg, state);
}
