//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module huffmanFixedAndCat(
  clk      ,
  rstn     ,
  //
  val_i    ,
  flg_lit_i,
  lit_dat_i,
  len_dat_i,
  dis_dat_i 
  //
  );

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD  = 'd8; /*`LOG2(256)*/
  localparam LEN_DAT_WD  = 'd7; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD  = 'd7; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam LIT_CODE_WD = 'd9;
  localparam LEN_CODE_WD = 'd10; // huffman 7 bits + extra 3 bits
  localparam DIS_CODE_WD = 'd9;  // huffman 5 bits + extra 4 bits
  localparam CODE_WD_WD  = 'd4;  /*`LOG2(CODE_WD_MAX)*/

//***   INPUT / OUTPUT   ******************************************************
  //
  input                     clk          ;
  input                     rstn         ;
  //
  input                     val_i        ;
  input                     flg_lit_i    ;
  input [LIT_DAT_WD  -1 :0] lit_dat_i    ;
  input [LEN_DAT_WD  -1 :0] len_dat_i    ;
  input [DIS_DAT_WD  -1 :0] dis_dat_i    ;

//***   WIRE / REG   **********************************************************
  // code
  reg   [LIT_CODE_WD -1 :0] lit_code_w   ;
  reg   [LEN_CODE_WD -1 :0] len_code_w   ;
  reg   [DIS_CODE_WD -1 :0] dis_code_w   ;
  // code width
  reg   [CODE_WD_WD  -1 :0] lit_code_wd_w;
  reg   [CODE_WD_WD  -1 :0] len_code_wd_w;
  reg   [CODE_WD_WD  -1 :0] dis_code_wd_w;

//***   MAIN BODY   ***********************************************************
//---   CODE   --------------------------------------------
huffmanFixedCore huffmanFixedCore(.lit_dat_i    (lit_dat_i    ),
                                  .len_dat_i    (len_dat_i    ),
                                  .dis_dat_i    (dis_dat_i    ),
                                  .lit_code_o   (lit_code_w   ),
                                  .len_code_o   (len_code_w   ),
                                  .dis_code_o   (dis_code_w   ),
                                  .lit_code_wd_o(lit_code_wd_w),
                                  .len_code_wd_o(len_code_wd_w),
                                  .dis_code_wd_o(dis_code_wd_w) );


endmodule