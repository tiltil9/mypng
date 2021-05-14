//------------------------------------------------------------------------------
  //
  //  Filename      : filter_paeth.v
  //  Description   : paeth predictor 
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-15
  //
//------------------------------------------------------------------------------
  //  c b
  //  a x
//------------------------------------------------------------------------------

module filter_paeth(
  dat_a_i,
  dat_b_i,
  dat_c_i,
  dat_o
);

//***   PARAMETER   ***********************************************************
  parameter    DATA_WD = -1  ;

//***   INPUT / OUTPUT   ******************************************************
  input     [DATA_WD-1 :0]    dat_a_i  ;
  input     [DATA_WD-1 :0]    dat_b_i  ;
  input     [DATA_WD-1 :0]    dat_c_i  ;
  output    [DATA_WD-1 :0]    dat_o    ;


//***   WIRE / REG   **********************************************************
  wire    [DATA_WD+1-1 :0]      pa_w  ;
  wire    [DATA_WD+1-1 :0]      pb_w  ;
  wire    [DATA_WD+2-1 :0]      pc_w  ;

  wire signed [DATA_WD+1-1 :0]  pa_signed_w ;
  wire signed [DATA_WD+1-1 :0]  pb_signed_w ;
  wire signed [DATA_WD+2-1 :0]  pc_signed_w ;


//***   MAIN BODY   ***********************************************************
//---    Algorithm    -------------------------------------
  //     p  = a + b - c
  //     pa = abs(p - a) = abs(b - c)
  //     pb = abs(p - b) = abs(a - c)
  //     pc = abs(p - c) = abs(a + b - 2c)
  //     if min{pa, pb, pc} = px, o = x

  // px_signed_w
  assign pa_signed_w = $signed(dat_b_i           -  dat_c_i     ) ;
  assign pb_signed_w = $signed(dat_a_i           -  dat_c_i     ) ;
  assign pc_signed_w = $signed(dat_a_i + dat_b_i - (dat_c_i << 1)) ;

  // px_w
  assign pa_w = pa_signed_w[DATA_WD+1-1] ? -pa_signed_w : pa_signed_w ;
  assign pb_w = pb_signed_w[DATA_WD+1-1] ? -pb_signed_w : pb_signed_w ;
  assign pc_w = pc_signed_w[DATA_WD+2-1] ? -pc_signed_w : pc_signed_w ;

  // dat_o
  assign dat_o = (pa_w <= pb_w && pa_w <= pc_w) ? dat_a_i :
                 (pb_w <= pc_w)                 ? dat_b_i :
                                                  dat_c_i ;
endmodule