//------------------------------------------------------------------------------
  //
  //  Filename      : lz77_detect_one
  //  Description   : detect the mininal position of the one
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-05-04
  //
//------------------------------------------------------------------------------
  // if dat_i = 0, then pos_o = 65
//------------------------------------------------------------------------------

module lz77_detect_one(
  dat_i,
  pos_o
);

//***   PARAMETER   ***********************************************************
  localparam DAT_WD     = 'd64                  ;
  // localparam DAT_LVL    = 2                     ;
  localparam LVL_HIG_WD = 'd8                   ; // lvl -> level
  localparam LVL_LOW_WD = 'd8                   ; // lvl -> level
  localparam POS_WD     = (`LOG2(DAT_WD) + 'd1) ;

//***   INPUT / OUTPUT   ******************************************************
  input  [DAT_WD-1 :0] dat_i ;
  output [POS_WD-1 :0] pos_o ;

//***   WIRE / REG   **********************************************************
  wire   [LVL_HIG_WD-1 :0] lvl_hig_w ;
  reg    [LVL_LOW_WD-1 :0] lvl_low_w ;

  reg    [POS_WD    -1 :0] pos_hig_w ;
  reg    [POS_WD    -1 :0] pos_low_w ;

//***   MAIN BODY   ***********************************************************
  // lvl_hig_w
  genvar i;
  generate 
      for( i = 0; i < LVL_HIG_WD; i = i + 1) begin
          assign lvl_hig_w[i] = dat_i[LVL_LOW_WD*i +: LVL_LOW_WD]!=0 ;
      end
  endgenerate

  // lvl_low_w / pos_hig_w
  always@(*) begin
    casex(lvl_hig_w)
      8'b???????1: begin lvl_low_w = dat_i[ 7: 0] ; pos_hig_w = 'd0  ; end
      8'b??????10: begin lvl_low_w = dat_i[15: 8] ; pos_hig_w = 'd8  ; end
      8'b?????100: begin lvl_low_w = dat_i[23:16] ; pos_hig_w = 'd16 ; end
      8'b????1000: begin lvl_low_w = dat_i[31:24] ; pos_hig_w = 'd24 ; end
      8'b???10000: begin lvl_low_w = dat_i[39:32] ; pos_hig_w = 'd32 ; end
      8'b??100000: begin lvl_low_w = dat_i[47:40] ; pos_hig_w = 'd40 ; end
      8'b?1000000: begin lvl_low_w = dat_i[55:48] ; pos_hig_w = 'd48 ; end
      8'b10000000: begin lvl_low_w = dat_i[63:56] ; pos_hig_w = 'd56 ; end
      default    : begin lvl_low_w = 'd0          ; pos_hig_w = 'd56 ; end
    endcase
  end

  // pos_low_w
  always@(*) begin
    casex(lvl_low_w)
      8'b???????1: pos_low_w = 'd0 ;
      8'b??????10: pos_low_w = 'd1 ;
      8'b?????100: pos_low_w = 'd2 ;
      8'b????1000: pos_low_w = 'd3 ;
      8'b???10000: pos_low_w = 'd4 ;
      8'b??100000: pos_low_w = 'd5 ;
      8'b?1000000: pos_low_w = 'd6 ;
      8'b10000000: pos_low_w = 'd7 ;
      default    : pos_low_w = 'd8 ;
    endcase
  end

  // pos_o
  assign pos_o = pos_hig_w + pos_low_w + 'd1;

  endmodule