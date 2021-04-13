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
  input  [DATA_WD -1 :0]  dat_i  ;
  input                   lst_i  ;
  output                  done_o ;
  output                  val_o  ;
  output [DATA_WD -1 :0]  dat_o  ;

  //*** WIRE/REG **************************************************************


  //*** MAIN BODY *************************************************************


endmodule