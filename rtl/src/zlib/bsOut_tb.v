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

module bsOut_tb;

//***   PARAMETER   ***********************************************************
  localparam DATA_WD  = 'd32;
  localparam NUMB_WD  = 'd5 ;

//***   INPUT / OUTPUT   ******************************************************
  reg                   clk    ;
  reg                   rstn   ;
  reg                   val_i  ;
  reg  [DATA_WD -1 :0]  dat_i  ;
  reg  [NUMB_WD -1 :0]  numb_i ;
  wire                  val_o  ;
  wire [DATA_WD -1 :0]  dat_o  ;

//***   MAIN BODY   ***********************************************************
//---   INST   --------------------------------------------
bsOut dut(.clk    (clk    ),
          .rstn   (rstn   ),
          .val_i  (val_i  ),
          .dat_i  (dat_i  ),
          .numb_i (numb_i ),
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
    numb_i = 'd0;
    #(5 * `CLK_FULL);
    @(negedge clk); // !!! this delay is essential.

    @(posedge clk);
    @(negedge clk);
    @(posedge clk);
    dat_i = 32'h00000409;
    val_i = 1'b1;
    numb_i = 'd15;
    @(negedge clk);
    @(posedge clk);
    val_i = 1'b0; 
    dat_i = 32'h0;
    numb_i = 'd0;

    @(negedge clk);
    @(posedge clk);
    dat_i = 32'h09040409;
    val_i = 1'b1;
    numb_i = 'd31;
    @(negedge clk);
    @(posedge clk);
    val_i = 1'b0; 
    dat_i = 32'h0;
    numb_i = 'd0;

    @(negedge clk);
    @(posedge clk);
    dat_i = 32'h0000000f;
    val_i = 1'b1;
    numb_i = 'd3;
    @(negedge clk);
    @(posedge clk);
    val_i = 1'b0; 
    dat_i = 32'h0;
    numb_i = 'd0;

    @(posedge clk);
    @(negedge clk);
    @(posedge clk);
    dat_i = 32'h0000abcd;
    val_i = 1'b1;
    numb_i = 'd15;
    @(negedge clk);
    @(posedge clk);
    val_i = 1'b0; 
    dat_i = 32'h0;
    numb_i = 'd0;

  end


endmodule