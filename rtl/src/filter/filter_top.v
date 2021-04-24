//------------------------------------------------------------------------------
  //
  //  Filename      : filter_top
  //  Description   : filter with fifo
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-14
  //
//------------------------------------------------------------------------------

module filter_top(
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
    // fifo_flt_wr
    fifo_flt_wr_val_o ,
    fifo_flt_wr_dat_o
);


//***   PARAMETER   ***********************************************************
  // global

  // derived


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                               clk                ;
  input                               rstn               ;

  // cfg_i
  input         [`SIZE_W_WD-1   :0]   cfg_w_i            ;
  input         [`SIZE_H_WD-1   :0]   cfg_h_i            ;

  // ctl_if
  input                               start_i            ;
  output                              done_o             ;

  // dat
  input                               val_i              ;
  input         [`DATA_PXL_WD-1 :0]   dat_i              ;

  // fifo_flt_wr
  output                              fifo_flt_wr_val_o  ;
  output        [`DATA_PXL_WD-1 :0]   fifo_flt_wr_dat_o  ;
  

//***   WIRE / REG   **********************************************************
  // itf 
  wire          [`SIZE_H_WD-1   :0]   cnt_h_o_w            ;

  // fifo_cur
  wire                                fifo_cur_wr_val_o_w  ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_cur_wr_dat_o_w  ;
  wire                                fifo_cur_rd_val_o_w  ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_cur_rd_dat_i_w  ;

  // fifo_pre_rd
  wire                                fifo_pre_rd_val_o_w  ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_pre_rd_dat_i_w  ;

  // fifo_0
  wire                                fifo_0_wr_val_w      ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_0_wr_dat_w      ;
  wire                                fifo_0_rd_val_w      ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_0_rd_dat_w      ;
  
  // fifo_1
  wire                                fifo_1_wr_val_w      ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_1_wr_dat_w      ;
  wire                                fifo_1_rd_val_w      ;
  wire          [`DATA_PXL_WD-1 :0]   fifo_1_rd_dat_w      ;


//***   MAIN BODY   ***********************************************************
//---   filter   ------------------------------------------
  filter filter(
    // global
    .clk                ( clk                 ) ,
    .rstn               ( rstn                ) ,
    // cfg_i
    .cfg_h_i            ( cfg_h_i             ) ,
    .cfg_w_i            ( cfg_w_i             ) ,
    // ctl_if
    .start_i            ( start_i             ) ,
    .done_o             ( done_o              ) ,
    .cnt_h_o            ( cnt_h_o_w           ) ,
    // dat
    .val_i              ( val_i               ) ,
    .dat_i              ( dat_i               ) ,
    // fifo_cur
    .fifo_cur_wr_val_o  ( fifo_cur_wr_val_o_w ) ,
    .fifo_cur_wr_dat_o  ( fifo_cur_wr_dat_o_w ) ,
    .fifo_cur_rd_val_o  ( fifo_cur_rd_val_o_w ) ,
    .fifo_cur_rd_dat_i  ( fifo_cur_rd_dat_i_w ) ,
    // fifo_flt_wr
    .fifo_flt_wr_val_o  ( fifo_flt_wr_val_o   ) ,
    .fifo_flt_wr_dat_o  ( fifo_flt_wr_dat_o   ) ,
    // fifo_pre_rd
    .fifo_pre_rd_val_o  ( fifo_pre_rd_val_o_w ) ,
    .fifo_pre_rd_dat_i  ( fifo_pre_rd_dat_i_w )
  );


//---   fifo_pre/cur   ------------------------------------
  // fifo_cur/pre_rd
  assign fifo_0_rd_val_w     = (cnt_h_o_w[0]=='d0) ? fifo_cur_rd_val_o_w : fifo_pre_rd_val_o_w ;
  assign fifo_1_rd_val_w     = (cnt_h_o_w[0]=='d1) ? fifo_cur_rd_val_o_w : fifo_pre_rd_val_o_w ;
  assign fifo_cur_rd_dat_i_w = (cnt_h_o_w[0]=='d0) ? fifo_0_rd_dat_w     : fifo_1_rd_dat_w     ;
  assign fifo_pre_rd_dat_i_w = (cnt_h_o_w[0]=='d1) ? fifo_0_rd_dat_w     : fifo_1_rd_dat_w     ;

  // fifo_cur_wr
  assign fifo_0_wr_val_w     = (cnt_h_o_w[0]=='d0) ? fifo_cur_wr_val_o_w : 'd0;
  assign fifo_0_wr_dat_w     = (cnt_h_o_w[0]=='d0) ? fifo_cur_wr_dat_o_w : 'd0;
  assign fifo_1_wr_val_w     = (cnt_h_o_w[0]=='d1) ? fifo_cur_wr_val_o_w : 'd0;
  assign fifo_1_wr_dat_w     = (cnt_h_o_w[0]=='d1) ? fifo_cur_wr_dat_o_w : 'd0;


//---   fifo_0   ------------------------------------------
  fifo #(
      .SIZE        (`SIZE_W_MAX      ) ,
      .DATA_WD     (`DATA_PXL_WD     )
  )fifo_0(
      // global
      .clk         ( clk             ) ,
      .rstn        ( rstn            ) ,
      // cfg 
      .cfg_w_i     ( cfg_w_i         ),
      // write
      .wr_val_i    ( fifo_0_wr_val_w ) ,
      .wr_dat_i    ( fifo_0_wr_dat_w ) ,
      // read
      .rd_ack_i    ( fifo_0_rd_val_w ) ,
      .rd_dat_o    ( fifo_0_rd_dat_w )
  );


//---   fifo_1   ------------------------------------------
  fifo #(
      .SIZE        (`SIZE_W_MAX      ) ,
      .DATA_WD     (`DATA_PXL_WD     )
  )fifo_1(
      // global
      .clk         ( clk             ) ,
      .rstn        ( rstn            ) ,
      // cfg 
      .cfg_w_i     ( cfg_w_i         ),
      // write
      .wr_val_i    ( fifo_1_wr_val_w ) ,
      .wr_dat_i    ( fifo_1_wr_dat_w ) ,
      // read
      .rd_ack_i    ( fifo_1_rd_val_w ) ,
      .rd_dat_o    ( fifo_1_rd_dat_w )
  );


endmodule