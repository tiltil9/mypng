//------------------------------------------------------------------------------
//
//  Filename      : fifo.v
//  Description   : register-based fifo
//  Author        : Tingting Li
//  Email         : 1107319548@qq.com
//  Created       : 2021-04-14
//
//------------------------------------------------------------------------------

`include "defines.vh"

module fifo(
    // global
    clk         ,
    rstn        ,
    // write
    wr_val_i    ,
    wr_dat_i    ,
    wr_ful_o    ,
    // read
    rd_val_i    ,
    rd_val_o    ,
    rd_dat_o    ,
    rd_ept_o    ,
    // common
    wd_usd_o
);


//***   PARAMETER   ***********************************************************
  // global
  parameter     SIZE       = -1             ;
  parameter     DATA_WD    = -1             ;

  // derived
  localparam    SIZE_WD    = `LOG2( SIZE )  ;


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                             clk       ;
  input                             rstn      ;

  // write
  input                             wr_val_i  ;
  input          [DATA_WD-1  :0]    wr_dat_i  ;
  output                            wr_ful_o  ;
  
  // read
  input                             rd_val_i  ;
  output                            rd_val_o  ;
  output        [DATA_WD-1   :0]    rd_dat_o  ;
  output                            rd_ept_o  ;

  // common
  output reg    [SIZE_WD+1-1 :0]    wd_usd_o  ;


//***   WIRE / REG   **********************************************************
  reg           [SIZE_WD-1   :0]    wr_adr_r  ;
  reg           [SIZE_WD-1   :0]    rd_adr_r  ;
  wire          [SIZE_WD-1   :0]    adr_w     ;


//***   MAIN BODY   ***********************************************************
//---   WRITE   -----------------------------------------
  // wr_ful_o
  assign wr_ful_o = wd_usd_o == SIZE ;

  // wr_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      wr_adr_r <= 'd0 ;
    end
    else if( wr_val_i ) begin
      if( wr_adr_r == SIZE - 'd1 ) begin
        wr_adr_r <= 'd0 ;
      end
      else begin
        wr_adr_r <= wr_adr_r + 'd1 ;
      end
    end
  end


//---   READ   ------------------------------------------
  // rd_ept_o
  assign rd_ept_o = wd_usd_o == 'd0 ;

  // rd_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      rd_adr_r <= 'd0 ;
    end
    else if(rd_val_i) begin
      if( rd_adr_r == SIZE - 'd1 ) begin
        rd_adr_r <= 'd0 ;
      end
      else begin
        rd_adr_r <= rd_adr_r + 'd1 ;
      end
    end
  end 


//---   COMMON   ------------------------------------------
  // adr_w
  assign adr_w = wr_val_i ? wr_adr_r : 
                 rd_val_i ? rd_adr_r :
                            'd0      ;

  // wd_usd_o
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      wd_usd_o <= 'd0 ;
    end
    else if( wr_val_i ) begin
      if( wd_usd_o == SIZE ) begin
        wd_usd_o <= wd_usd_o ;
      end
      else begin
        wd_usd_o <= wd_usd_o + 'd1 ;
      end
    end
    else if( rd_val_i ) begin
      if( wd_usd_o == 'd0 ) begin
        wd_usd_o <= wd_usd_o ;
      end
      else begin
        wd_usd_o <= wd_usd_o - 'd1 ;
      end
    end
  end

//--- MEMORY ARRAY ----------------------------------------
  // ram
  ram #(
    .SIZE     ( SIZE    ),
    .DATA_WD  ( DATA_WD )
  ) ram(
    .clk      ( clk      ),
    .rstn     ( rstn     ),
    .adr_i    ( adr_w    ),
    .wr_val_i ( wr_val_i ),
    .wr_dat_i ( wr_dat_i ),
    .rd_val_i ( rd_val_i ),
    .rd_val_o ( rd_val_o ),
    .rd_dat_o ( rd_dat_o )
  );

endmodule