//------------------------------------------------------------------------------
  //
  //  Filename      : sim_filter_top.v
  //  Description   : testbench for filter top
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-23
  //
//------------------------------------------------------------------------------

// `define SIZE_W 'd256
// `define SIZE_H 'd256
// `define SIZE_W 'd480
// `define SIZE_H 'd360
// `define SIZE_W 'd393
// `define SIZE_H 'd501
// `define SIZE_W 'd440
// `define SIZE_H 'd330
`define SIZE_W 'd512
`define SIZE_H 'd512



//--- LOCAL (CONSTANT) -----------------
  // clock
  `define CLK_FULL           10
  `define CLK_HALF           ( `CLK_FULL / 2 )

  // input file
  `define FILTER_I_FILE      "../data/filter_i_rgba.dat"

  // outout file
  `define FILTER_O_FILE      "../data/filter_o_scanlines.dat"


module sim_filter_top();


//*** INPUT/OUTPUT *************************************************************
  // global
  reg                          clk                ;
  reg                          rstn               ;

  // cfg_i
  reg    [`SIZE_W_WD-1   :0]   cfg_w_i            ;
  reg    [`SIZE_H_WD-1   :0]   cfg_h_i            ;

  // ctl_if
  reg                          start_i            ;
  wire                         done_o             ;

  // dat
  reg                          val_i              ;
  reg    [`DATA_PXL_WD-1 :0]   dat_i              ;

  // fifo_flt_wr
  wire                         fifo_flt_wr_val_o  ;
  wire   [`DATA_PXL_WD-1 :0]   fifo_flt_wr_dat_o  ;


//*** WIRE/REG *****************************************************************
  // counter
  integer                      cnt_h_r        ;
  integer                      cyc_start_r    ;
  integer                      cyc_done_r     ;


`include "D:/Documents/OneDrive/O_2021_SPRING/1M_VLSI/PJ/PNG/mypng/rtl/sim/sim_filter/sub_bench.vh"


//***   MAIN BODY   ***********************************************************
//--- PROC -----------------------------
  // clk
  initial begin
    clk = 'd0 ;
    forever begin
      #`CLK_HALF ;
      clk = ! clk ;
    end
  end

  // rstn
  initial begin
    rstn = 'd0 ;
    #( 5 * `CLK_FULL );
    @(negedge clk );
    rstn = 'd1 ;
  end

  // main
  initial begin
    // initial
    cfg_w_i = `SIZE_W ;   // alphaBall
    cfg_h_i = `SIZE_H ;
    start_i = 'd0   ;
    val_i   = 'd0   ;
    dat_i   = 'd0   ;

    // delay
    #( 5 * `CLK_FULL );
    
    // log
    $display( "\n\n***   CHECK STARTS   ***\n" );

    // delay
    #( 5 * `CLK_FULL );
    $display( "" );

    // core loop
    for( cnt_h_r = 'd0 ; cnt_h_r < `SIZE_H ; cnt_h_r = cnt_h_r + 'd1 ) begin
      // log
      $write( "\t at %06d ns, starting scanline %04d ... ", $time, cnt_h_r );
        // start
        @(negedge clk ) ;
        start_i = 'd1 ;
        @(posedge clk ) ;
        cyc_start_r = $time / `CLK_FULL ;
        @(negedge clk ) ;
        start_i = 'd0 ;

        // initial
        -> filter_data_i_event ;

        // wait
        @(posedge done_o ) ;
        @(posedge clk ) ;
        cyc_done_r = $time / `CLK_FULL ;
        $display( "(delta cycle %04d)", (cyc_done_r - cyc_start_r));

        // delay
        #( 10 * `CLK_FULL );
    end

      // log
      # ( 10 * `CLK_FULL ) ;
      $display( "\n\n***   CHECK DONES   ***\n");
      $stop ;
  end


//--- INST -----------------------------
filter_top dut(
    // global
    .clk               ( clk               ),
    .rstn              ( rstn              ),
    // cfg_i
    .cfg_w_i           ( cfg_w_i           ),
    .cfg_h_i           ( cfg_h_i           ),
    // ctl_if
    .start_i           ( start_i           ),
    .done_o            ( done_o            ),
    // dat
    .val_i             ( val_i             ),
    .dat_i             ( dat_i             ),
    // fifo_flt_wr
    .fifo_flt_wr_val_o ( fifo_flt_wr_val_o ),
    .fifo_flt_wr_dat_o ( fifo_flt_wr_dat_o )
);

endmodule




