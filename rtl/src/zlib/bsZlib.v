//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module bsZlib(
  clk      ,
  rstn     ,
  //
  start_i  ,
  val_i    ,
  flg_lit_i,
  lit_dat_i,
  len_dat_i,
  dis_dat_i,
  lst_i    ,
  //
  done_o   ,
  val_o    ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD  = 'd8 ; /*`LOG2(256)*/
  localparam LEN_DAT_WD  = 'd7 ; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD  = 'd7 ; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam DATA_WD     = 'd32;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk      ;
  input                      rstn     ;
  //
  input                      start_i  ;
  input                      val_i    ;
  input                      flg_lit_i;
  input  [LIT_DAT_WD  -1 :0] lit_dat_i;
  input  [LEN_DAT_WD  -1 :0] len_dat_i;
  input  [DIS_DAT_WD  -1 :0] dis_dat_i;
  input                      lst_i    ;
  //
  output                     done_o   ;
  output                     val_o    ;
  output [DATA_WD     -1 :0] dat_o    ;

//***   WIRE / REG   **********************************************************

//***   MAIN BODY   ***********************************************************


endmodule