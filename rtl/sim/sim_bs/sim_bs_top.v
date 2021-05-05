//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

//---   LOCAL (CONSTANT)   --------------------------------
  // clock
  `define CLK_FULL    10
  `define CLK_HALF    (`CLK_FULL / 2)

  // init
  `define BS_I_FILE      "./check_data/bs_i.dat"

  // chko
  `define BS_O_FILE      "./check_data/bs_o.dat"


module sim_bs_top;

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD = 'd8 ; /*`LOG2(256)*/
  localparam LEN_DAT_WD = 'd7 ; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD = 'd7 ; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam DATA_WD    = 'd32;

//***   INPUT / OUTPUT   ******************************************************
  reg                         clk           ;
  reg                         rstn          ;
  reg                         start_i       ;
  reg                         val_i         ;
  reg                         flg_lit_i     ;
  reg     [LIT_DAT_WD  -1 :0] lit_dat_i     ;
  reg     [LEN_DAT_WD  -1 :0] len_dat_i     ;
  reg     [DIS_DAT_WD  -1 :0] dis_dat_i     ;
  reg                         lst_i         ;
  reg                         adler32_done_i;
  reg     [DATA_WD     -1 :0] adler32_dat_i ;
  wire                        done_o        ;
  wire                        val_o         ;
  wire    [DATA_WD     -1 :0] dat_o         ;

//***   WIRE / REG   **********************************************************
  // flag
  integer                     lst_flg_r     ;

  // counter
  integer                     cnt_dat_r     ;

//***   SUB BENCH   ***********************************************************
  `include "./sub_bench.vh"

//***   MAIN BODY   ***********************************************************
//---   PROC   --------------------------------------------
  // clk
  initial begin
    clk = 1'b0 ;
    forever begin
      #`CLK_HALF;
      clk = ~clk;
    end
  end

  // rstn
  initial begin
    rstn = 1'b0;
    #(5 * `CLK_FULL);
    @(negedge clk);
    rstn = 'd1 ;
  end

  // main
  initial begin
    // initial
    start_i        = 'd0;
    val_i          = 'd0;
    flg_lit_i      = 'd0;
    lit_dat_i      = 'd0;
    len_dat_i      = 'd0;
    dis_dat_i      = 'd0;
    lst_i          = 'd0;
    adler32_done_i = 'd0;
    adler32_dat_i  = 'd0; 

    // delay
    #(5 * `CLK_FULL);
    $display("\n\n***   CHECK STARTS   ***\n");

    // delay
    #(5 * `CLK_FULL);
    $display("");

    // core
    // start
    @(negedge clk);
    start_i = 'd1;
    @(posedge clk);
    @(negedge clk);
    start_i = 'd0;
    // !!! wait for init done (hack code)
    #(10 * `CLK_FULL);
    // loop
    cnt_dat_r = 'd0;
    lst_flg_r = 'd0;
    while (lst_flg_r != 'd1) begin
      // log
      $display("\t at %10d ns, launching data %10d ... ", $time, cnt_dat_r);

      // init
      -> init_bs_i_event;

      // valid
      @(negedge clk);
      val_i = 'd1;
      @(posedge clk);
      @(negedge clk);
      val_i = 'd0;

      // delay
      #(10 * `CLK_FULL);

      // update
      cnt_dat_r = cnt_dat_r + 'd1;
    end

    // !!! no need to wait done_o (hack code)

    // log
    # (10 * `CLK_FULL) ;
    $display("\n\n***   CHECK DONES   ***\n");
    $finish;
  end

//---   INST   --------------------------------------------
  bs_top dut(.clk           (clk           ),
             .rstn          (rstn          ),
             .start_i       (start_i       ),
             .val_i         (val_i         ),
             .flg_lit_i     (flg_lit_i     ),
             .lit_dat_i     (lit_dat_i     ),
             .len_dat_i     (len_dat_i     ),
             .dis_dat_i     (dis_dat_i     ),
             .lst_i         (lst_i         ),
             .adler32_done_i(adler32_done_i),
             .adler32_dat_i (adler32_dat_i ),
             .done_o        (done_o        ),
             .val_o         (val_o         ),
             .dat_o         (dat_o         ) );


endmodule