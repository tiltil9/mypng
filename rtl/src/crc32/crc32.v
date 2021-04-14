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

module crc32(
    clk    ,
    rstn   ,
    start_i,
    val_i  ,
    dat_i  ,
    lst_i  ,
    done_o ,
    val_o  ,
    dat_o
  ); // !!! only crc32_core now

//*** PARAMETER ***************************************************************
  localparam DATA_WD  = 'd32;
  localparam CRC32_WD = 'd32;

//*** IN/OUT ******************************************************************
  input                   clk    ;
  input                   rstn   ;
  input                   start_i;
  input                   val_i  ;
  input  [8       -1 :0]  dat_i  ; // !!! temp width
  input                   lst_i  ;
  output                  done_o ;
  output                  val_o  ;
  output [DATA_WD -1 :0]  dat_o  ;

  //*** WIRE/REG **************************************************************
  // crc32 and din in normal order
  wire   [8        -1 :0] din_nrm_w      ;
  reg    [CRC32_WD -1 :0] crc32_nrm_cur_r;
  reg    [CRC32_WD -1 :0] crc32_nrm_nxt_w;

  //*** MAIN BODY *************************************************************

  assign din_nrm_w = dat_i;
  // crc32_nrm_nxt_w[31:0] calculated according to crc32_nrm_cur_r[31:0] and din_nrm_w[7:0]
  // ploy 0x04C11DB7
  // these codes are modified according to easics crc generation tool
  always @(*) begin
    crc32_nrm_nxt_w[0 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[1 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[2 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[3 ] = crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[4 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[5 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[6 ] = crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[7 ] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[8 ] = crc32_nrm_cur_r[0] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[9 ] = crc32_nrm_cur_r[1] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[10] = crc32_nrm_cur_r[2] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[11] = crc32_nrm_cur_r[3] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[12] = crc32_nrm_cur_r[4] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[13] = crc32_nrm_cur_r[5] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[14] = crc32_nrm_cur_r[6] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[15] = crc32_nrm_cur_r[7] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[16] = crc32_nrm_cur_r[8] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[0] ^ din_nrm_w[4] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[17] = crc32_nrm_cur_r[9] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[1] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[18] = crc32_nrm_cur_r[10] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[2] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[19] = crc32_nrm_cur_r[11] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[20] = crc32_nrm_cur_r[12] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[21] = crc32_nrm_cur_r[13] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[22] = crc32_nrm_cur_r[14] ^ crc32_nrm_cur_r[24] ^ din_nrm_w[0];
    crc32_nrm_nxt_w[23] = crc32_nrm_cur_r[15] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[24] = crc32_nrm_cur_r[16] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[25] = crc32_nrm_cur_r[17] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ din_nrm_w[2] ^ din_nrm_w[3];
    crc32_nrm_nxt_w[26] = crc32_nrm_cur_r[18] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[27] = crc32_nrm_cur_r[19] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[28] = crc32_nrm_cur_r[20] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[2] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[29] = crc32_nrm_cur_r[21] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[30] = crc32_nrm_cur_r[22] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[4] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[31] = crc32_nrm_cur_r[23] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[5];
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      crc32_nrm_cur_r <= /*CRC32_WD*/32'hffff_ffff;
    end
    else if(val_i) begin
      crc32_nrm_cur_r <= crc32_nrm_nxt_w;
    end
  end

  assign dat_o = crc32_nrm_cur_r;


endmodule