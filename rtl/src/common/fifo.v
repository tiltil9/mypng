//------------------------------------------------------------------------------
//
//  Filename      : fifo.v
//  Description   : register-based fifo for mypng which writes once and read three times
//  Author        : Tingting Li
//  Email         : 1107319548@qq.com
//  Created       : 2021-04-14
//
//------------------------------------------------------------------------------

module fifo(
    // global
    clk         ,
    rstn        ,
    // cfg 
    cfg_w_i     ,
    // write
    wr_val_i    ,
    wr_dat_i    ,
    // read
    rd_val_i    ,
    rd_dat_o
);


//***   PARAMETER   ***********************************************************
  // global
  parameter     SIZE       = -1               ;
  parameter     DATA_WD    = -1               ;

  // derived
  localparam    SIZE_WD    = `LOG2( SIZE )    ;
  localparam    CYC_WD     = `LOG2( SIZE )    ;


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                             clk       ;
  input                             rstn      ;

  // cfg_i
  input         [`SIZE_W_WD-1:0]    cfg_w_i   ;

  // write
  input                             wr_val_i  ;
  input         [DATA_WD-1  :0]     wr_dat_i  ;
  
  // read
  input                             rd_val_i  ;
  output        [DATA_WD-1   :0]    rd_dat_o  ;


//***   WIRE / REG   **********************************************************
  // common
  wire          [SIZE_WD-1   :0]    adr_w     ;

  // write
  reg           [SIZE_WD-1   :0]    wr_adr_r  ;

  // read
  reg           [SIZE_WD-1   :0]    rd_adr_r  ;


//***   MAIN BODY   ***********************************************************
//---   COMMON   ------------------------------------------
  // adr_w
  assign adr_w = wr_val_i ? wr_adr_r : 
                 rd_val_i ? rd_adr_r :
                            'd0      ;


//---   WRITE   -----------------------------------------
  // wr_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      wr_adr_r <= 'd0 ;
    end
    else if( wr_val_i ) begin
      if( wr_adr_r == cfg_w_i - 'd1 ) begin
        wr_adr_r <= 'd0 ;
      end
      else begin
        wr_adr_r <= wr_adr_r + 'd1 ;
      end
    end
  end


//---   READ   ------------------------------------------
  // rd_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      rd_adr_r <= 'd0 ;
    end
    else if( rd_val_i ) begin
      if( rd_adr_r == cfg_w_i - 'd1 ) begin
        rd_adr_r <= 'd0 ;
      end
      else begin
        rd_adr_r <= rd_adr_r + 'd1 ;
      end
    end
  end 


//--- MEMORY ARRAY ----------------------------------------
  `ifndef IMPL_TSMC90
  // ram
  ram #(
    .SIZE     ( SIZE       ),
    .DATA_WD  ( DATA_WD    )
  )ram_0(
  // global
    .clk      ( clk        ),
    .rstn     ( rstn       ),
  // common
    .adr_i    ( adr_w      ),
  // write
    .wr_val_i ( wr_val_i   ),
    .wr_dat_i ( wr_dat_i   ),
  // read
    .rd_val_i ( rd_val_i   ),
    .rd_val_o ( /*UNUSED*/ ),
    .rd_dat_o ( rd_dat_o   )
  );
  `else
  // ram
  SRAM32x512_1rw ram_0(
  // global
    .CSB      ( 1'd0       ),
    .CE       ( clk        ),
  // common
    .A        ( adr_w      ),
  // write
    .WEB      ( !wr_val_i  ),
    .I        ( wr_dat_i   ),
  // read
    .OEB      ( 1'd0       ),
    .O        ( rd_dat_o   )
  );
  `endif

endmodule