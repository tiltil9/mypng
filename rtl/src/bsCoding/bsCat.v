//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module bsCat(
  clk   ,
  rstn  ,
  //
  val_i ,
  dat_i ,
  numb_i,
  //
  val_o ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD         = 'd32;
  localparam NUMB_WD         = 'd5 ;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk   ;
  input                      rstn  ;
  //
  input                      val_i ;
  input      [DATA_WD -1 :0] dat_i ;
  input      [NUMB_WD -1 :0] numb_i; // means 1~32 least significant bits are valid
  //
  output reg                 val_o ;
  output     [DATA_WD -1 :0] dat_o ;

//***   WIRE / REG   **********************************************************

//***   MAIN BODY   ***********************************************************


endmodule