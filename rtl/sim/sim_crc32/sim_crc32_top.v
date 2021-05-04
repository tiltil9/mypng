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
  `define CRC32_I_FILE      "./check_data/crc32_i.dat"

  // chko
  `define CRC32_O_FILE      "./check_data/crc32_o.dat"


module sim_crc32_top;

//***   PARAMETER   ***********************************************************
  localparam DATA_WD  = 'd32;
  localparam NUM_WD   = 'd2 ;
  localparam SIZE_PIC_WD  = 'd32;

//***   INPUT / OUTPUT   ******************************************************
  reg                         clk      ;
  reg                         rstn     ;
  reg     [SIZE_PIC_WD -1 :0] w_i      ;
  reg     [SIZE_PIC_WD -1 :0] h_i      ;
  reg                         start_i  ;
  reg                         val_i    ;
  reg     [DATA_WD     -1 :0] dat_i    ;
  reg     [NUM_WD      -1 :0] num_i    ;
  reg                         lst_i    ;
  wire                        done_o   ;
  wire                        val_o    ;
  wire    [DATA_WD     -1 :0] dat_o    ;

//***   WIRE / REG   **********************************************************
  // flag
  integer                     lst_flg_r;

  // counter
  integer                     cnt_dat_r;

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
    w_i     = 'd0;
    h_i     = 'd0;
    start_i = 'd0;
    val_i   = 'd0;
    dat_i   = 'd0;
    num_i   = 'd0;
    lst_i   = 'd0;

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
      -> init_crc32_i_event;

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

    // !!! wait (hack code)
    @(posedge done_o);
    @(posedge clk);

    // log
    # (10 * `CLK_FULL) ;
    $display("\n\n***   CHECK DONES   ***\n");
    $finish;
  end

//---   INST   --------------------------------------------
  crc32_top dut(.clk    (clk    ),
                .rstn   (rstn   ),
                .w_i    (w_i    ),
                .h_i    (h_i    ),
                .start_i(start_i),
                .val_i  (val_i  ),
                .dat_i  (dat_i  ),
                .num_i  (num_i  ),
                .lst_i  (lst_i  ),
                .done_o (done_o ),
                .val_o  (val_o  ),
                .dat_o  (dat_o  ) );


endmodule