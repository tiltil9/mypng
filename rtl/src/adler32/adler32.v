//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module adler32(
    clk    ,
    rstn   ,
    start_i,
    val_i  ,
    dat_i  ,
    lst_i  ,
    done_o ,
    val_o  ,
    dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD         = 'd32;
  localparam ADLER32_WD      = 'd32;
  localparam ADLER32_HALF_WD = 'd16;
  localparam DIN_WD          = 'd8 ;
  localparam DIN_CNT         = DATA_WD / DIN_WD;
  localparam DIN_CNT_WD      = /*`LOG2(DIN_CNT)*/ 'd2;

//***   INPUT / OUTPUT   ******************************************************
  input                            clk             ;
  input                            rstn            ;
  input                            start_i         ;
  input                            val_i           ;
  input  [DATA_WD           -1 :0] dat_i           ;
  input                            lst_i           ;
  output                           done_o          ;
  output                           val_o           ;
  output [DATA_WD           -1 :0] dat_o           ;

//***   WIRE / REG   **********************************************************
  // din count
  reg    [DIN_CNT_WD        -1 :0] din_cnt_r       ;

  // din
  reg    [DIN_WD            -1 :0] din_w           ;

  // adler32 s2 and s1
  reg    [ADLER32_HALF_WD   -1 :0] adler32_s2_cur_r;
  reg    [ADLER32_HALF_WD   -1 :0] adler32_s1_cur_r;

  // adler32 s2 and s1 calculation
  wire   [ADLER32_HALF_WD+2 -1 :0] adler32_s2_nxt_sum_w;
  wire   [ADLER32_HALF_WD+1 -1 :0] adler32_s1_nxt_sum_w;

  wire   [ADLER32_HALF_WD   -1 :0] adler32_s2_nxt_w;
  wire   [ADLER32_HALF_WD   -1 :0] adler32_s1_nxt_w;

//***   MAIN BODY   ***********************************************************
//---   COUNT   -------------------------------------------
  // din count
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      din_cnt_r <= 'd0;
    end
    else begin
      if(din_cnt_r == DIN_CNT - 'd1) begin
        din_cnt_r <= 'd0;
      end
      else if(val_i || din_cnt_r != 'd0) begin
        din_cnt_r <= din_cnt_r + 'd1;
      end
    end
  end

//---   CALC   --------------------------------------------
  // dat_i[31:24], [23:16], [15:8], [7:0] mapped to din_w[7:0]
  always @(*) begin
    din_w = 'd0;
    case(din_cnt_r)
      'd0    : din_w = dat_i[31:24];
      'd1    : din_w = dat_i[23:16];
      'd2    : din_w = dat_i[15: 8];
      'd3    : din_w = dat_i[ 7: 0];
      default: din_w = 'd0;
    endcase
  end

  // adler32 s2 and s1
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      adler32_s2_cur_r <= 16'h0000;
      adler32_s1_cur_r <= 16'h0001;
    end
    else if(val_i || din_cnt_r != 'd0) begin
      adler32_s2_cur_r <= adler32_s2_nxt_w;
      adler32_s1_cur_r <= adler32_s1_nxt_w;
    end
  end

  // sum
  assign adler32_s2_nxt_sum_w = adler32_s2_cur_r + (adler32_s1_cur_r + din_w);
  assign adler32_s1_nxt_sum_w = adler32_s1_cur_r + din_w;

  // mod
  assign adler32_s2_nxt_w = adler32_s2_nxt_sum_w % 16'd65521; // TODO: to remove mod?
  assign adler32_s1_nxt_w = adler32_s1_nxt_sum_w % 16'd65521;

//---   OUTPUT   ------------------------------------------
  // adler32
  assign dat_o = (adler32_s2_cur_r << 'd16) | adler32_s1_cur_r;


endmodule