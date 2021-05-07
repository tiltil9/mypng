//------------------------------------------------------------------------------
//
//  Filename      : fifo.v
//  Description   : register-based pre-reading specific fifo for filter which writes once and read once
//  Author        : Tingting Li
//  Email         : 1107319548@qq.com
//  Created       : 2021-05-07
//
//------------------------------------------------------------------------------

module fifo_flt(
    // global
    clk         ,
    rstn        ,
    // cfg 
    cfg_w_i     ,
    // write
    wr_val_i    ,
    wr_dat_i    ,
    // read
    rd_ack_i    ,
    rd_dat_o
);


//***   PARAMETER   ***********************************************************
  // global
  parameter     SIZE       = -1               ;
  parameter     DATA_WD    = -1               ;

  // local
  localparam    CYC        = 'd3              ; // cyc -> cycle

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
  input                             rd_ack_i  ;
  output        [DATA_WD-1   :0]    rd_dat_o  ;


//***   WIRE / REG   **********************************************************
  // write
  reg           [SIZE_WD-1   :0]    wr_adr_r  ;

  // read
  reg           [SIZE_WD-1   :0]    rd_adr_r  ;
  reg                               rd_rdy_r  ;
  wire                              rd_val_w  ;
  wire                              rd_ept_w  ;

  reg           [CYC_WD-1    :0]    cnt_r     ; // write 1 time, read 1 times


//***   MAIN BODY   ***********************************************************
//---   COMMON   ------------------------------------------
  // cnt_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_r <= 'd0 ;
    end
    else if( cnt_r == CYC - 'd1) begin
      cnt_r <= 'd0 ;
    end
    else if((wr_adr_r == cfg_w_i) || (rd_adr_r == cfg_w_i)) begin
      cnt_r <= cnt_r + 'd1 ;
    end
  end


//---   WRITE   -----------------------------------------
  // wr_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      wr_adr_r <= 'd0 ;
    end
    else if( wr_val_i ) begin
      if( wr_adr_r == cfg_w_i) begin
        wr_adr_r <= 'd0 ;
      end
      else begin
        wr_adr_r <= wr_adr_r + 'd1 ;
      end
    end
  end


//---   READ   ------------------------------------------
  // rd_rdy_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      rd_rdy_r <= 'd0 ;
    end
    else begin
      if( rd_val_w ) begin
        rd_rdy_r <= 'd1 ;
      end
      else if( rd_ack_i )begin
        rd_rdy_r <= 'd0 ;
      end
    end
  end
    
  // rd_val_w
  assign rd_val_w = !rd_ept_w && (!rd_rdy_r || rd_ack_i);

  // rd_ept_w
  assign rd_ept_w = (cnt_r == 'd0 || cnt_r == CYC-'d1);

  // rd_adr_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      rd_adr_r <= 'd0 ;
    end
    else if( rd_val_w ) begin
      if( rd_adr_r == cfg_w_i) begin
        rd_adr_r <= 'd0 ;
      end
      else begin
        rd_adr_r <= rd_adr_r + 'd1 ;
      end
    end
  end 


//--- MEMORY ARRAY ----------------------------------------
  // ram
  ram #(
    .SIZE     ( SIZE       ),
    .DATA_WD  ( DATA_WD    )
  )ram_0(
    .clk      ( clk        ),
    .rstn     ( rstn       ),
    .wr_val_i ( wr_val_i   ),
    .wr_dat_i ( wr_dat_i   ),
    .wr_adr_i ( wr_adr_r   ),
    .rd_val_i ( rd_val_w   ),
    .rd_adr_i ( rd_adr_r   ),
    .rd_val_o ( /*UNUSED*/ ),
    .rd_dat_o ( rd_dat_o   )
  );

endmodule