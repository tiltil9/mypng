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


//*** Filter DUMP *************************************************************
void dumpFilter(unsigned char** out, const unsigned char* in, unsigned w, unsigned h)
{
  FILE* fpt;
 
  // dump ori rgba
  fpt = fopen("../../rtl/sim/sim_filter/data/filter_i_rgba.dat","w");
  for (unsigned y = 0; y < h ; ++y){
    for (unsigned x = 0; x < w; ++x){
      for (unsigned chn = 0; chn < 4; ++chn)
        fprintf(fpt, "%02x", int(*(in + y * w * 4 + x * 4 + chn)));
      fprintf(fpt, " ");
    }
    fprintf(fpt, "\n");
  }
  fclose(fpt); 

  // dump preProcessScanlines
  fpt = fopen("../../rtl/sim/sim_filter/data/filter_o_scanlines.dat","w");
  for (unsigned y = 0; y < h ; ++y){
    fprintf(fpt, "%02x000000 ", int(*(*out + y * (w * 4 + 1))));  // filter type
    for (unsigned x = 0; x < w; ++x){
        for (unsigned chn = 0; chn < 4; ++chn)
          fprintf(fpt, "%02x", int(*(*out + y * (w * 4 + 1) + (x * 4 + 1) + chn)));
        fprintf(fpt, " ");
      }
    fprintf(fpt, "\n");
  }
  fclose(fpt); 
}


//*** ADLER32 DUMP *************************************************************
void dumpAdler32(const unsigned char* in, size_t insize, unsigned adler32)
{
  FILE* fpt;
 
  // dump uncompressed
  fpt = fopen("../../rtl/sim/sim_adler32/adler32_i_uncompressed.dat","w");
  size_t i = 0;
  size_t len = insize;
  while(len > 0) {
    if(len > 4) {
      fprintf(fpt, "%x\n", 0); // lst_i
      fprintf(fpt, "%x\n", 3); // num_i
      fprintf(fpt, "%02x%02x%02x%02x\n", in[i] & 0xff, in[i + 1] & 0xff, in[i + 2] & 0xff, in[i + 3] & 0xff); // dat_i
      i = i + 4;
      len = len - 4;
    }
    else {
      fprintf(fpt, "%x\n", 1);         // lst_i
      fprintf(fpt, "%x\n", (unsigned)(len - 1)); // num_i
      if(len == 4) {
        fprintf(fpt, "%02x%02x%02x%02x\n", in[i] & 0xff, in[i + 1] & 0xff, in[i + 2] & 0xff, in[i + 3] & 0xff); // dat_i
      }
      else if(len == 3) {
        fprintf(fpt, "%02x%02x%02x%02x\n", in[i] & 0xff, in[i + 1] & 0xff, in[i + 2] & 0xff, 0 & 0xff); // dat_i
      }
      else if(len == 2) {
        fprintf(fpt, "%02x%02x%02x%02x\n", in[i] & 0xff, in[i + 1] & 0xff, 0 & 0xff, 0 & 0xff); // dat_i
      }
      else if(len == 1) {
        fprintf(fpt, "%02x%02x%02x%02x\n", in[i] & 0xff, 0 & 0xff, 0 & 0xff, 0 & 0xff); // dat_i
      }
      i = i + len;
      len = len - len;
    }
  }
  fclose(fpt);

  // dump value
  fpt = fopen("../../rtl/sim/sim_adler32/adler32_o_value.dat","w");
  fprintf(fpt, "%x\n", adler32);
  fclose(fpt);
}


//*** LZ77 DUMP *************************************************************
void dumpLz77(const unsigned int* in, size_t insize){
  FILE* fpt;

  fpt = fopen("../../rtl/sim/sim_lz77/check_data/lz77_o.dat","w");
  for (unsigned i = 0; i < insize ; i = i + 2){
    if ( in[i] == 1) { // literalFlag = true
      fprintf(fpt, "1 %02x\n", in[i + 1]);
    }
    else {
      fprintf(fpt, "0 %02x %02x\n", in[i + 1], in[i + 2]);
      i = i + 1;
    }
  }

  fclose(fpt); 
}