//------------------------------------------------------------------------------
  //
  //  Filename      : sim_png_top.v
  //  Description   : testbench for png top
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-05-07
  //
//------------------------------------------------------------------------------

`define SIZE_W 'd256
`define SIZE_H 'd256
// `define SIZE_W 'd480
// `define SIZE_H 'd360
// `define SIZE_W 'd393
// `define SIZE_H 'd501
// `define SIZE_W 'd440
// `define SIZE_H 'd330



//--- LOCAL (CONSTANT) -----------------
  // clock
  `define CLK_FULL           10
  `define CLK_HALF           ( `CLK_FULL / 2 )

  // input file
  `define PNG_I_FILE      "../check_data/RGBA.dat"

  // outout file
  `define PNG_O_FILE      "../check_data/bs_o.dat"
  `define PNG_DUMP_O_FILE "../check_data/dump_bs_o.dat"
  `define FILTER_O_FILE   "../check_data/Filtered.dat"
  `define LZ77_O_FILE     "../check_data/Lz77.dat"


module sim_png_top();


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
  wire                         val_o              ;
  wire   [`DATA_PXL_WD-1 :0]   dat_o              ;


//*** WIRE/REG *****************************************************************
  // counter
  integer                      cnt_h_r        ;
  integer                      cyc_start_r    ;
  integer                      cyc_done_r     ;
  integer                      cyc_all_r      ;


`include "D:/Documents/OneDrive/O_2021_SPRING/1M_VLSI/PJ/PNG/mypng/rtl/sim/sim_png/sub_bench.vh"


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
    cyc_all_r = 'd0 ;

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
      $write( "\t at %06d ns, starting png %04d ... ", $time, cnt_h_r );
        // start
        @(negedge clk ) ;
        start_i = 'd1 ;
        @(posedge clk ) ;
        cyc_start_r = $time / `CLK_FULL ;
        @(negedge clk ) ;
        start_i = 'd0 ;

        // initial
        -> png_data_i_event ;

        // wait
        @(posedge dut.lz77_top.done_o ) ;
        @(posedge clk ) ;
        cyc_done_r = $time / `CLK_FULL ;
        $display( "(delta cycle %04d)", (cyc_done_r - cyc_start_r));
        cyc_all_r = cyc_all_r + (cyc_done_r - cyc_start_r);

        // delay
        #( 10 * `CLK_FULL );
    end
      // wait
      @(posedge dut.done_o ) ;

      // log
      # ( 10 * `CLK_FULL ) ;
      $display( "\n\n***   CHECK DONES   ***\n");
        $display( "(delta cycle %04d)", cyc_all_r);
      $stop ;
  end


//--- INST -----------------------------
png_top dut(
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
    .val_o             ( val_o             ),
    .dat_o             ( dat_o             )
);

endmodule




