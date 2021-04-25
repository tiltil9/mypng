//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module bsCat(
  clk   ,
  rstn  ,
  //
  val_i ,
  dat_i ,
  numb_i,
  //
  val_o ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD         = 'd32;
  localparam NUMB_WD         = 'd5 ;

  localparam PTR_OUT_BUF_WD  = 'd5 ; /*`LOG2(DATA_WD)*/

//***   INPUT / OUTPUT   ******************************************************
  //
  input                             clk          ;
  input                             rstn         ;
  //
  input                             val_i        ;
  input      [DATA_WD        -1 :0] dat_i        ;
  input      [NUMB_WD        -1 :0] numb_i       ; // means 1~32 least significant bits are valid
  //
  output reg                        val_o        ;
  output     [DATA_WD        -1 :0] dat_o        ;

//***   WIRE / REG   **********************************************************
  // numb plus 1
  wire       [NUMB_WD+1      -1 :0] numb_pls1_w  ;

  // dat_i mask
  wire       [DATA_WD        -1 :0] dat_i_msk_w  ;

  // output buffer
  reg        [DATA_WD*2      -1 :0] dat_out_buf_r;
  reg        [PTR_OUT_BUF_WD -1 :0] ptr_out_buf_r;

//***   MAIN BODY   ***********************************************************
//---   MISC   --------------------------------------------
  // numb plus 1
  assign numb_pls1_w = numb_i + 'd1;

  // dat_i mask
  assign dat_i_msk_w = (1'b1 << numb_pls1_w) - 'd1;

//---   CAT   ---------------------------------------------
  // data output buffer
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      dat_out_buf_r <= 'd0;
    end
    else if (val_i) begin
      dat_out_buf_r <= (dat_out_buf_r << numb_pls1_w) | (dat_i & dat_i_msk_w); // mask precede bit of dat_i with 0 so that precede bit does not matter
    end
  end

  // pointer output buffer
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      ptr_out_buf_r <= 'd0;
    end
    else if (val_i) begin
      ptr_out_buf_r <= (ptr_out_buf_r + numb_pls1_w >= DATA_WD) ? (ptr_out_buf_r + numb_pls1_w - DATA_WD) : (ptr_out_buf_r + numb_pls1_w);
    end
  end

//---   OUTPUT   ------------------------------------------
  // val_o
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      val_o <= 'd0;
    end
    else begin
      if (val_i && ptr_out_buf_r + numb_pls1_w >= DATA_WD) begin
        val_o <= 'd1;
      end
      else begin
        val_o <= 'd0;
      end
    end
  end

  // dat_o
  assign dat_o = (dat_out_buf_r >> ptr_out_buf_r); // least significant [DATA_WD -1 :0] // TODO: reverse per byte


endmodule