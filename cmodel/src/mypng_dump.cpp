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


//*** DUMP TOOL ****************************************************************
void dumpWhData(FILE* fpt, unsigned w, unsigned h)
{
  fprintf(fpt, "%08x %08x", w, h);
}

void dumpRGBAData(FILE* fpt, const unsigned char* image, unsigned w, unsigned h)
{
  for (unsigned y = 0; y < h ; ++y) {
    for (unsigned x = 0; x < w; ++x) {
      for (unsigned chn = 0; chn < 4; ++chn) {
        fprintf(fpt, "%02x", int(*(image + y * w * 4 + x * 4 + chn)));
      }
      fprintf(fpt, " ");
    }
    fprintf(fpt, "\n");
  }
}

void dumpFilteredData(FILE* fpt, const unsigned char* dataFiltered, unsigned w, unsigned h)
{
  for (unsigned y = 0; y < h ; ++y) {
    fprintf(fpt, "%02x000000 ", int(*(dataFiltered + y * (w * 4 + 1)))); // filter type
    for (unsigned x = 0; x < w; ++x) {
      for (unsigned chn = 0; chn < 4; ++chn) {
        fprintf(fpt, "%02x", int(*(dataFiltered + y * (w * 4 + 1) + (x * 4 + 1) + chn)));
      }
      fprintf(fpt, " ");
    }
    fprintf(fpt, "\n");
  }
}

void dumpFilteredAdler32Data(FILE* fpt, const unsigned char* dataFiltered, unsigned w, unsigned h)
{
  for (unsigned y = 0; y < h ; ++y) {
    fprintf(fpt, "%02x %02x %02x000000\n", 0, 0, int(*(dataFiltered + y * (w * 4 + 1)))); // lst_i, num_i, dat_i
    for (unsigned x = 0; x < w; ++x) {
      fprintf(fpt, "%02x %02x ", (y == h - 1 && x == w - 1) , 3);
      for (unsigned chn = 0; chn < 4; ++chn) {
        fprintf(fpt, "%02x", int(*(dataFiltered + y * (w * 4 + 1) + (x * 4 + 1) + chn)));
      }
      fprintf(fpt, "\n");
    }
  }
}


void dumpAdler32Data(FILE* fpt, unsigned adler32)
{
  fprintf(fpt, "%08x\n", adler32);
}

void dumpLz77Data(FILE* fpt, const unsigned int* dataLz77, size_t dataLz77Size)
{
  size_t i = 0;
  while(i < dataLz77Size) {
    if ( dataLz77[i] == 1) { // literalFlag = true
      fprintf(fpt, "%02x ", (i + 2 >= dataLz77Size));                // lst_i
      fprintf(fpt, "%02x ", dataLz77[i]);                            // flg_lit_i
      fprintf(fpt, "%02x\n", dataLz77[i + 1]);                       // lit_dat_i
      i = i + 2;
    }
    else {
      fprintf(fpt, "%02x ", (i + 3 >= dataLz77Size));                // lst_i
      fprintf(fpt, "%02x ", dataLz77[i]);                            // flg_lit_i
      fprintf(fpt, "%02x %02x\n", dataLz77[i + 1], dataLz77[i + 2]); // len_dat_i, dis_dat_i
      i = i + 3;
    }
  }
}

void dumpZlibData(FILE* fpt, const unsigned char* dataZlib, size_t dataZlibSize)
{
  size_t i = 0;
  while(i < dataZlibSize) {
    fprintf(fpt, "%02x ", (i + 4 >= dataZlibSize));                                     // lst_i
    fprintf(fpt, "%02x ", (int)(i + 4 >= dataZlibSize ? dataZlibSize - i - 1 : 4 - 1)); // num_i
    if(dataZlibSize - i >= 4) {                                                         // dat_i
      fprintf(fpt, "%02x%02x%02x%02x\n", dataZlib[i] & 0xff, dataZlib[i + 1] & 0xff, dataZlib[i + 2] & 0xff, dataZlib[i + 3] & 0xff);
    }
    else if(dataZlibSize - i == 3) {
      fprintf(fpt, "%02x%02x%02x00\n", dataZlib[i] & 0xff, dataZlib[i + 1] & 0xff, dataZlib[i + 2] & 0xff);
    }
    else if(dataZlibSize - i == 2) {
      fprintf(fpt, "%02x%02x0000\n", dataZlib[i] & 0xff, dataZlib[i + 1] & 0xff);
    }
    else if(dataZlibSize - i == 1) {
      fprintf(fpt, "%02x000000\n", dataZlib[i] & 0xff);
    }
    i = i + (i + 4 >= dataZlibSize ? dataZlibSize - i : 4);
  }
  fprintf(fpt, "%08x ", (int)dataZlibSize); // for bs
}

void dumpCrc32Data(FILE* fpt, const unsigned char* dataPNG, size_t dataPNGSize)
{
  size_t crcpos = 0;
  // IDAT CRC32
  crcpos = dataPNGSize - 16;
  fprintf(fpt, "%02x%02x%02x%02x\n", dataPNG[crcpos] & 0xff, dataPNG[crcpos + 1] & 0xff, dataPNG[crcpos + 2] & 0xff, dataPNG[crcpos + 3] & 0xff);
  // IHDR CRC32
  crcpos = 0 + 29;
  fprintf(fpt, "%02x%02x%02x%02x\n", dataPNG[crcpos] & 0xff, dataPNG[crcpos + 1] & 0xff, dataPNG[crcpos + 2] & 0xff, dataPNG[crcpos + 3] & 0xff);
  // IEND CRC32
  crcpos = dataPNGSize - 4;
  fprintf(fpt, "%02x%02x%02x%02x\n", dataPNG[crcpos] & 0xff, dataPNG[crcpos + 1] & 0xff, dataPNG[crcpos + 2] & 0xff, dataPNG[crcpos + 3] & 0xff);
}
