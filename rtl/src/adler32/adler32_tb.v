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
`define CLK_FULL    10
`define CLK_HALF    (`CLK_FULL / 2)

module adler32_tb;

//***   PARAMETER   ***********************************************************
  localparam DATA_WD  = 'd32;

//***   INPUT / OUTPUT   ******************************************************
  reg                   clk    ;
  reg                   rstn   ;
  reg                   start_i;
  reg                   val_i  ;
  reg  [DATA_WD -1 :0]  dat_i  ;
  reg                   lst_i  ;
  wire                  done_o ;
  wire                  val_o  ;
  wire [DATA_WD -1 :0]  dat_o  ;

//***   MAIN BODY   ***********************************************************
//---   INST   --------------------------------------------
adler32 dut(.clk    (clk    ),
            .rstn   (rstn   ),
            .start_i(start_i),
            .val_i  (val_i  ),
            .dat_i  (dat_i  ),
            .lst_i  (lst_i  ),
            .done_o (done_o ),
            .val_o  (val_o  ),
            .dat_o  (dat_o  ) );

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
    val_i = 1'b0;
    start_i = 1'b0;
    lst_i = 1'b0;
    #(5 * `CLK_FULL);
    @(negedge clk); // !!! this delay is essential.

    @(posedge clk);
    start_i = 1'b1;
    @(negedge clk);
    @(posedge clk);
    start_i = 1'b0;
    @(negedge clk);
    @(posedge clk);
    dat_i = 32'h04090409; // must last at least four clock now
    val_i = 1'b1;
    @(negedge clk);
    @(posedge clk);
    val_i = 1'b0; // 00050005, 0013000e, 00250012, 0040001b
  end


endmodule