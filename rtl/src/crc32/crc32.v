//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module crc32(
  clk    ,
  rstn   ,
  //
  w_i    ,
  h_i    ,
  //
  start_i,
  val_i  ,
  dat_i  ,
  lst_i  ,
  //
  done_o ,
  val_o  ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD     = 'd32;
  localparam SIZE_PIC_WD = 'd32;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk            ;
  input                      rstn           ;
  //
  input  [SIZE_PIC_WD -1 :0] w_i            ;
  input  [SIZE_PIC_WD -1 :0] h_i            ;
  //
  input                      start_i        ;
  input                      val_i          ;
  input  [DATA_WD     -1 :0] dat_i          ;
  input                      lst_i          ;
  //
  output                     done_o         ;
  output                     val_o          ;
  output [DATA_WD     -1 :0] dat_o          ;

//***   WIRE / REG   **********************************************************

//***   MAIN BODY   ***********************************************************


endmodule