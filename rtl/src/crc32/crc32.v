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
  wire   [CRC32_WD -1 :0] crc32_nrm_nxt_w;

  // crc32 in reversed order
  wire   [CRC32_WD -1 :0] crc32_rvs_cur_w;

//*** MAIN BODY *************************************************************

  // reversed order dat_i mapped to normal order din_nrm_w
  assign din_nrm_w = {dat_i[0], dat_i[1], dat_i[2], dat_i[3], dat_i[4], dat_i[5], dat_i[6], dat_i[7]};

  // normal order crc32_nrm_cur_r
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      crc32_nrm_cur_r <= /*CRC32_WD*/32'hffff_ffff;
    end
    else if(val_i) begin
      crc32_nrm_cur_r <= crc32_nrm_nxt_w;
    end
  end
  // crc32_nrm_nxt_w[31:0] calculated according to crc32_nrm_cur_r[31:0] and din_nrm_w[7:0]
  crc32_nrm_8bits crc32_nrm_8bits(.crc32_nrm_cur_i(crc32_nrm_cur_r), .din_nrm_i(din_nrm_w), .crc32_nrm_nxt_o(crc32_nrm_nxt_w));

  // normal order crc32_nrm_cur_r mapped to reversed order crc32_rvs_cur_w
  assign crc32_rvs_cur_w = {crc32_nrm_cur_r[ 0], crc32_nrm_cur_r[ 1], crc32_nrm_cur_r[ 2], crc32_nrm_cur_r[ 3],
                            crc32_nrm_cur_r[ 4], crc32_nrm_cur_r[ 5], crc32_nrm_cur_r[ 6], crc32_nrm_cur_r[ 7],
                            crc32_nrm_cur_r[ 8], crc32_nrm_cur_r[ 9], crc32_nrm_cur_r[10], crc32_nrm_cur_r[11],
                            crc32_nrm_cur_r[12], crc32_nrm_cur_r[13], crc32_nrm_cur_r[14], crc32_nrm_cur_r[15],
                            crc32_nrm_cur_r[16], crc32_nrm_cur_r[17], crc32_nrm_cur_r[18], crc32_nrm_cur_r[19],
                            crc32_nrm_cur_r[20], crc32_nrm_cur_r[21], crc32_nrm_cur_r[22], crc32_nrm_cur_r[23],
                            crc32_nrm_cur_r[24], crc32_nrm_cur_r[25], crc32_nrm_cur_r[26], crc32_nrm_cur_r[27],
                            crc32_nrm_cur_r[28], crc32_nrm_cur_r[29], crc32_nrm_cur_r[30], crc32_nrm_cur_r[31] };

  // reversed order crc32_rvs_cur_w xor with 0xFFFFFFFF
  assign dat_o = crc32_rvs_cur_w ^ /*CRC32_WD*/32'hffff_ffff;


endmodule


//*** SUB MODULE ************************************************************
module crc32_nrm_8bits(crc32_nrm_cur_i, din_nrm_i, crc32_nrm_nxt_o);

  localparam DIN_WD   = 'd8 ;
  localparam CRC32_WD = 'd32;

  input      [CRC32_WD -1 :0] crc32_nrm_cur_i;
  input      [DIN_WD   -1 :0] din_nrm_i      ;
  output reg [CRC32_WD -1 :0] crc32_nrm_nxt_o;

  // crc32_nrm_nxt_o[31:0] calculated according to crc32_nrm_cur_i[31:0] and din_nrm_i[7:0]
  // poly is 0x04C11DB7
  // these codes are modified according to easics crc generation tool
  always @(*) begin
    crc32_nrm_nxt_o[0 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[0] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[1 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[2 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[3 ] = crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[4 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[0] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[4] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[5 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[3] ^ din_nrm_i[4] ^ din_nrm_i[5] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[6 ] = crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[4] ^ din_nrm_i[5] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[7 ] = crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[0] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[5] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[8 ] = crc32_nrm_cur_i[0 ] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[3] ^ din_nrm_i[4];
    crc32_nrm_nxt_o[9 ] = crc32_nrm_cur_i[1 ] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[4] ^ din_nrm_i[5];
    crc32_nrm_nxt_o[10] = crc32_nrm_cur_i[2 ] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[29] ^ din_nrm_i[0] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[5];
    crc32_nrm_nxt_o[11] = crc32_nrm_cur_i[3 ] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[3] ^ din_nrm_i[4];
    crc32_nrm_nxt_o[12] = crc32_nrm_cur_i[4 ] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[4] ^ din_nrm_i[5] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[13] = crc32_nrm_cur_i[5 ] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[5] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[14] = crc32_nrm_cur_i[6 ] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[2] ^ din_nrm_i[3] ^ din_nrm_i[4] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[15] = crc32_nrm_cur_i[7 ] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[3] ^ din_nrm_i[4] ^ din_nrm_i[5] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[16] = crc32_nrm_cur_i[8 ] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ din_nrm_i[0] ^ din_nrm_i[4] ^ din_nrm_i[5];
    crc32_nrm_nxt_o[17] = crc32_nrm_cur_i[9 ] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[1] ^ din_nrm_i[5] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[18] = crc32_nrm_cur_i[10] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[2] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[19] = crc32_nrm_cur_i[11] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[3] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[20] = crc32_nrm_cur_i[12] ^ crc32_nrm_cur_i[28] ^ din_nrm_i[4];
    crc32_nrm_nxt_o[21] = crc32_nrm_cur_i[13] ^ crc32_nrm_cur_i[29] ^ din_nrm_i[5];
    crc32_nrm_nxt_o[22] = crc32_nrm_cur_i[14] ^ crc32_nrm_cur_i[24] ^ din_nrm_i[0];
    crc32_nrm_nxt_o[23] = crc32_nrm_cur_i[15] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[0] ^ din_nrm_i[1] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[24] = crc32_nrm_cur_i[16] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[1] ^ din_nrm_i[2] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[25] = crc32_nrm_cur_i[17] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[27] ^ din_nrm_i[2] ^ din_nrm_i[3];
    crc32_nrm_nxt_o[26] = crc32_nrm_cur_i[18] ^ crc32_nrm_cur_i[24] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[0] ^ din_nrm_i[3] ^ din_nrm_i[4] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[27] = crc32_nrm_cur_i[19] ^ crc32_nrm_cur_i[25] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[1] ^ din_nrm_i[4] ^ din_nrm_i[5] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[28] = crc32_nrm_cur_i[20] ^ crc32_nrm_cur_i[26] ^ crc32_nrm_cur_i[29] ^ crc32_nrm_cur_i[30] ^ din_nrm_i[2] ^ din_nrm_i[5] ^ din_nrm_i[6];
    crc32_nrm_nxt_o[29] = crc32_nrm_cur_i[21] ^ crc32_nrm_cur_i[27] ^ crc32_nrm_cur_i[30] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[3] ^ din_nrm_i[6] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[30] = crc32_nrm_cur_i[22] ^ crc32_nrm_cur_i[28] ^ crc32_nrm_cur_i[31] ^ din_nrm_i[4] ^ din_nrm_i[7];
    crc32_nrm_nxt_o[31] = crc32_nrm_cur_i[23] ^ crc32_nrm_cur_i[29] ^ din_nrm_i[5];
  end

endmodule