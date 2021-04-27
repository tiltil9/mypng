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
