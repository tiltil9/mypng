//------------------------------------------------------------------------------
//
//  Filename      : ram.v
//  Description   : register-based simple dual-port ram
//  Author        : Tingting Li
//  Email         : 1107319548@qq.com
//  Created       : 2021-04-14
//
//------------------------------------------------------------------------------

module ram(
  // global
  clk         ,
  rstn        ,
  // write
  wr_val_i    ,
  wr_dat_i    ,
  wr_adr_i    ,
  // read
  rd_val_i    ,
  rd_adr_i    ,
  rd_val_o    ,
  rd_dat_o
);


//***   PARAMETER   ***********************************************************
  // global
  parameter     SIZE       = -1             ;
  parameter     DATA_WD    = -1             ;

  // derived
  localparam    SIZE_WD    = `LOG2( SIZE )  ;


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                           clk       ;
  input                           rstn      ;

  // write
  input                           wr_val_i  ;
  input         [DATA_WD-1 :0]    wr_dat_i  ;
  input         [SIZE_WD-1 :0]    wr_adr_i  ;
  
  // read
  input                           rd_val_i  ;
  input         [SIZE_WD-1 :0]    rd_adr_i  ;
  output reg                      rd_val_o  ;
  output reg    [DATA_WD-1 :0]    rd_dat_o  ;


//***   WIRE / REG   **********************************************************
  reg           [DATA_WD-1 :0]    mem_array[SIZE-1 :0]  ;


//***   MAIN BODY   ***********************************************************
//---   WRITE   -----------------------------------------
  // mem_array
  always @(posedge clk) begin
    if( wr_val_i ) begin
      mem_array[wr_adr_i] <= wr_dat_i ;
    end  
  end


//---   READ   ------------------------------------------
  // rd_val_o
  always @(posedge clk or negedge rstn) begin
    if( !rstn ) begin
      rd_val_o <= 'd0 ;
    end
    else begin
      rd_val_o <= rd_val_i ;
    end
  end

  // rd_dat_o
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      rd_dat_o <= 'd0 ;
    end
    else if( rd_val_i ) begin
      rd_dat_o <= mem_array[rd_adr_i] ;
    end
  end

endmodule
