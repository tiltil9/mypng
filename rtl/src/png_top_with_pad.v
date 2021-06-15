 //------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

 module png_top_with_pad(
    // global
    clk               ,
    rstn              ,
    // cfg_i
    cfg_w_i           ,
    cfg_h_i           ,
    // ctl_if
    start_i           ,
    done_o            ,
    // dat
    val_i             ,
    dat_i             ,
    val_o             ,
    dat_o
 );


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                               clk                ;
  input                               rstn               ;

  // cfg_i
  input                 [9-1   :0]    cfg_w_i            ;
  input                 [9-1   :0]    cfg_h_i            ;

  // ctl_if
  input                               start_i            ;
  output                              done_o             ;

  // dat
  input                               val_i              ;
  input                 [32-1 :0]     dat_i              ;
  output                              val_o              ;
  output                [32-1 :0]     dat_o              ;


//***   WIRE / REG   **********************************************************
  // global
  wire                               clk_w               ;
  wire                               rstn_w              ;

  // cfg_i
  wire                  [9-1   :0]   cfg_w_i_w           ;
  wire                  [9-1   :0]   cfg_h_i_w           ;

  // ctl_if
  wire                               start_i_w           ;
  wire                               done_o_w            ;

  // dat
  wire                               val_i_w             ;
  wire                  [32-1 :0]    dat_i_w             ;
  wire                               val_o_w             ;
  wire                  [32-1 :0]    dat_o_w             ;


//***   MAIN BODY   ***********************************************************
//---   png_top   ---------------------------------------------
png_top png_top(
    // global
    .clk         ( clk_w      )      ,
    .rstn        ( rstn_w     )      ,
    // cfg_i
    .cfg_w_i     ( cfg_w_i_w  )      ,
    .cfg_h_i     ( cfg_h_i_w  )      ,
    // ctl_if
    .start_i     ( start_i_w  )      ,
    .done_o      ( done_o_w   )      ,
    // dat
    .val_i       ( val_i_w    )      ,
    .dat_i        (dat_i_w    )      ,
    .val_o       ( val_o_w    )      ,
    .dat_o       ( dat_o_w    )
);


//---   pad   ---------------------------------------------
//    I1025 (PADIO, VSS, VDDIO, VDD, R_EN, VSSIO, DOUT)
I1025 I1025_clk       (.PADIO ( clk        ), .R_EN ( 1'd1 ), .DOUT ( clk_w        ));
I1025 I1025_rstn      (.PADIO ( rstn       ), .R_EN ( 1'd1 ), .DOUT ( rstn_w       ));
I1025 I1025_start_i   (.PADIO ( start_i    ), .R_EN ( 1'd1 ), .DOUT ( start_i_w    ));
I1025 I1025_val_i     (.PADIO ( val_i      ), .R_EN ( 1'd1 ), .DOUT ( val_i_w      ));

I1025 I1025_cfg_w_i_0 (.PADIO ( cfg_w_i[0] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[0] ));
I1025 I1025_cfg_w_i_1 (.PADIO ( cfg_w_i[1] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[1] ));
I1025 I1025_cfg_w_i_2 (.PADIO ( cfg_w_i[2] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[2] ));
I1025 I1025_cfg_w_i_3 (.PADIO ( cfg_w_i[3] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[3] ));
I1025 I1025_cfg_w_i_4 (.PADIO ( cfg_w_i[4] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[4] ));
I1025 I1025_cfg_w_i_5 (.PADIO ( cfg_w_i[5] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[5] ));
I1025 I1025_cfg_w_i_6 (.PADIO ( cfg_w_i[6] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[6] ));
I1025 I1025_cfg_w_i_7 (.PADIO ( cfg_w_i[7] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[7] ));
I1025 I1025_cfg_w_i_8 (.PADIO ( cfg_w_i[8] ), .R_EN ( 1'd1 ), .DOUT ( cfg_w_i_w[8] ));

I1025 I1025_cfg_h_i_0 (.PADIO ( cfg_h_i[0] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[0] ));
I1025 I1025_cfg_h_i_1 (.PADIO ( cfg_h_i[1] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[1] ));
I1025 I1025_cfg_h_i_2 (.PADIO ( cfg_h_i[2] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[2] ));
I1025 I1025_cfg_h_i_3 (.PADIO ( cfg_h_i[3] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[3] ));
I1025 I1025_cfg_h_i_4 (.PADIO ( cfg_h_i[4] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[4] ));
I1025 I1025_cfg_h_i_5 (.PADIO ( cfg_h_i[5] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[5] ));
I1025 I1025_cfg_h_i_6 (.PADIO ( cfg_h_i[6] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[6] ));
I1025 I1025_cfg_h_i_7 (.PADIO ( cfg_h_i[7] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[7] ));
I1025 I1025_cfg_h_i_8 (.PADIO ( cfg_h_i[8] ), .R_EN ( 1'd1 ), .DOUT ( cfg_h_i_w[8] ));

I1025 I1025_dat_i_0   (.PADIO ( dat_i[0]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[0]   ));
I1025 I1025_dat_i_1   (.PADIO ( dat_i[1]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[1]   ));
I1025 I1025_dat_i_2   (.PADIO ( dat_i[2]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[2]   ));
I1025 I1025_dat_i_3   (.PADIO ( dat_i[3]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[3]   ));
I1025 I1025_dat_i_4   (.PADIO ( dat_i[4]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[4]   ));
I1025 I1025_dat_i_5   (.PADIO ( dat_i[5]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[5]   ));
I1025 I1025_dat_i_6   (.PADIO ( dat_i[6]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[6]   ));
I1025 I1025_dat_i_7   (.PADIO ( dat_i[7]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[7]   ));
I1025 I1025_dat_i_8   (.PADIO ( dat_i[8]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[8]   ));
I1025 I1025_dat_i_9   (.PADIO ( dat_i[9]   ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[9]   ));
I1025 I1025_dat_i_10  (.PADIO ( dat_i[10]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[10]  ));
I1025 I1025_dat_i_11  (.PADIO ( dat_i[11]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[11]  ));
I1025 I1025_dat_i_12  (.PADIO ( dat_i[12]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[12]  ));
I1025 I1025_dat_i_13  (.PADIO ( dat_i[13]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[13]  ));
I1025 I1025_dat_i_14  (.PADIO ( dat_i[14]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[14]  ));
I1025 I1025_dat_i_15  (.PADIO ( dat_i[15]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[15]  ));
I1025 I1025_dat_i_16  (.PADIO ( dat_i[16]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[16]  ));
I1025 I1025_dat_i_17  (.PADIO ( dat_i[17]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[17]  ));
I1025 I1025_dat_i_18  (.PADIO ( dat_i[18]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[18]  ));
I1025 I1025_dat_i_19  (.PADIO ( dat_i[19]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[19]  ));
I1025 I1025_dat_i_20  (.PADIO ( dat_i[20]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[20]  ));
I1025 I1025_dat_i_21  (.PADIO ( dat_i[21]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[21]  ));
I1025 I1025_dat_i_22  (.PADIO ( dat_i[22]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[22]  ));
I1025 I1025_dat_i_23  (.PADIO ( dat_i[23]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[23]  ));
I1025 I1025_dat_i_24  (.PADIO ( dat_i[24]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[24]  ));
I1025 I1025_dat_i_25  (.PADIO ( dat_i[25]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[25]  ));
I1025 I1025_dat_i_26  (.PADIO ( dat_i[26]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[26]  ));
I1025 I1025_dat_i_27  (.PADIO ( dat_i[27]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[27]  ));
I1025 I1025_dat_i_28  (.PADIO ( dat_i[28]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[28]  ));
I1025 I1025_dat_i_29  (.PADIO ( dat_i[29]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[29]  ));
I1025 I1025_dat_i_30  (.PADIO ( dat_i[30]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[30]  ));
I1025 I1025_dat_i_31  (.PADIO ( dat_i[31]  ), .R_EN ( 1'd1 ), .DOUT ( dat_i_w[31]  ));

//       B12I1025 (PADIO, VSS, EN, VDDIO, PULL_UP, VDD, VSSIO, DOUT, PULL_DOWN, DIN)
B12I1025 B12I1025_done_o   (.PADIO ( done_o    ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN (done_o_w     ));
B12I1025 B12I1025_val_o    (.PADIO ( val_o     ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN (val_o_w      ));

B12I1025 B12I1025_dat_o_0  (.PADIO ( dat_o[0]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[0]  ));
B12I1025 B12I1025_dat_o_1  (.PADIO ( dat_o[1]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[1]  ));
B12I1025 B12I1025_dat_o_2  (.PADIO ( dat_o[2]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[2]  ));
B12I1025 B12I1025_dat_o_3  (.PADIO ( dat_o[3]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[3]  ));
B12I1025 B12I1025_dat_o_4  (.PADIO ( dat_o[4]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[4]  ));
B12I1025 B12I1025_dat_o_5  (.PADIO ( dat_o[5]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[5]  ));
B12I1025 B12I1025_dat_o_6  (.PADIO ( dat_o[6]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[6]  ));
B12I1025 B12I1025_dat_o_7  (.PADIO ( dat_o[7]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[7]  ));
B12I1025 B12I1025_dat_o_8  (.PADIO ( dat_o[8]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[8]  ));
B12I1025 B12I1025_dat_o_9  (.PADIO ( dat_o[9]  ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[9]  ));
B12I1025 B12I1025_dat_o_10 (.PADIO ( dat_o[10] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[10] ));
B12I1025 B12I1025_dat_o_11 (.PADIO ( dat_o[11] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[11] ));
B12I1025 B12I1025_dat_o_12 (.PADIO ( dat_o[12] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[12] ));
B12I1025 B12I1025_dat_o_13 (.PADIO ( dat_o[13] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[13] ));
B12I1025 B12I1025_dat_o_14 (.PADIO ( dat_o[14] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[14] ));
B12I1025 B12I1025_dat_o_15 (.PADIO ( dat_o[15] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[15] ));
B12I1025 B12I1025_dat_o_16 (.PADIO ( dat_o[16] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[16] ));
B12I1025 B12I1025_dat_o_17 (.PADIO ( dat_o[17] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[17] ));
B12I1025 B12I1025_dat_o_18 (.PADIO ( dat_o[18] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[18] ));
B12I1025 B12I1025_dat_o_19 (.PADIO ( dat_o[19] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[19] ));
B12I1025 B12I1025_dat_o_20 (.PADIO ( dat_o[20] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[20] ));
B12I1025 B12I1025_dat_o_21 (.PADIO ( dat_o[21] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[21] ));
B12I1025 B12I1025_dat_o_22 (.PADIO ( dat_o[22] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[22] ));
B12I1025 B12I1025_dat_o_23 (.PADIO ( dat_o[23] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[23] ));
B12I1025 B12I1025_dat_o_24 (.PADIO ( dat_o[24] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[24] ));
B12I1025 B12I1025_dat_o_25 (.PADIO ( dat_o[25] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[25] ));
B12I1025 B12I1025_dat_o_26 (.PADIO ( dat_o[26] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[26] ));
B12I1025 B12I1025_dat_o_27 (.PADIO ( dat_o[27] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[27] ));
B12I1025 B12I1025_dat_o_28 (.PADIO ( dat_o[28] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[28] ));
B12I1025 B12I1025_dat_o_29 (.PADIO ( dat_o[29] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[29] ));
B12I1025 B12I1025_dat_o_30 (.PADIO ( dat_o[30] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[30] ));
B12I1025 B12I1025_dat_o_31 (.PADIO ( dat_o[31] ), .EN ( 1'd1 ), .PULL_UP ( 1'd1 ), .PULL_DOWN ( 1'd1 ), .DIN ( dat_o_w[31] ));

 endmodule