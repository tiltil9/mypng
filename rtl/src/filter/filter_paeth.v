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
  wire    [DATA_WD+2-1 :0]      pa_w  ;
  wire    [DATA_WD+2-1 :0]      pb_w  ;
  wire    [DATA_WD+2-1 :0]      pc_w  ;


//***   MAIN BODY   ***********************************************************
//---    Algorithm    -------------------------------------
  //     p  = a + b - c
  //     pa = abs(p - a) = abs(b - c)
  //     pb = abs(p - b) = abs(a - c)
  //     pc = abs(p - c) = abs(a + b - 2c)
  //     if min{pa, pb, pc} = px, o = x

  // px_w
  assign pa_w = dat_b_i > dat_c_i ? (dat_b_i - dat_c_i) : (dat_c_i - dat_b_i) ;
  assign pb_w = dat_a_i > dat_c_i ? (dat_a_i - dat_c_i) : (dat_c_i - dat_a_i) ;
  assign pc_w = (dat_a_i + dat_b_i > 2*dat_c_i) ? 
                (dat_a_i + dat_b_i - 2*dat_c_i) : 
                (2*dat_c_i - dat_a_i - dat_b_i) ;

  // dat_o
  assign dat_o = (pa_w <= pb_w && pa_w <= pc_w) ? dat_a_i :
                 (pb_w <= pc_w)                 ? dat_b_i :
                                                  dat_c_i ;
endmodule