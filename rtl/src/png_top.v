//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module png_top(
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
    dat_o             ,
)

//***   PARAMETER   ***********************************************************
  // global

  // derived

//***   INPUT / OUTPUT   ******************************************************
  // global


//***   WIRE / REG   **********************************************************


//***   MAIN BODY   ***********************************************************
//---   filter   ---------------------------------------------
assign scanline_start_i = 
// todo: req
  filter_top filter_top(
      // global
      .clk               ( clk               ),
      .rstn              ( rstn              ),
      // cfg_i
      .cfg_w_i           ( cfg_w_i           ),
      .cfg_h_i           ( cfg_h_i           ),
      // ctl_if
      .start_i           ( scanline_start_i  ),
      .done_o            ( done_o            ),
      // dat
      .val_i             ( val_i             ),
      .dat_i             ( dat_i             ),
      // fifo_flt_wr
      .fifo_flt_wr_val_o ( fifo_flt_wr_val_o ),
      .fifo_flt_wr_dat_o ( fifo_flt_wr_dat_o )
  );


//---   fifo_flt   ---------------------------------------------
  fifo #(
      .SIZE        (`SIZE_W_MAX        ),
      .DATA_WD     (`DATA_PXL_WD       )
  )fifo_flt(
      // global
      .clk         ( clk               ),
      .rstn        ( rstn              ),
      // cfg 
      .cfg_w_i     ( cfg_w_i           ),
      // write
      .wr_val_i    ( fifo_flt_wr_val_o ),
      .wr_dat_i    ( fifo_flt_wr_dat_o ),
      // read
      .rd_ack_i    ( fifo_flt_rd_val_o ),
      .rd_dat_o    ( fifo_flt_rd_dat_i )
  );


//---   lz77   ---------------------------------------------
assign lz77_start_w = ;
lz77_top lz77_top(
    // global
    .clk               ( clk               ),
    .rstn              ( rstn              ),
    // cfg_i
    .cfg_w_i           ( cfg_w_i           ),
    .cfg_h_i           ( cfg_h_i           ),
    // ctl_if
    .start_i           ( lz77_start_w      ),
    .done_o            ( lz77_done_o       ),
    // dat
    .val_o             ( lz77_val_o        ),
    .flg_lit_o         ( lz77_flg_lit_o    ),
    .dat_lit_o         ( lz77_dat_lit_o    ),
    .dat_len_o         ( lz77_dat_len_o    ),
    .dat_dst_o         ( lz77_dat_dst_o    ),
    .flg_lst_o         ( lz77_flg_lst_o    ),
    // fifo_flt_rd
    .fifo_flt_rd_val_o ( fifo_flt_rd_val_o ),
    .fifo_flt_rd_dat_i ( fifo_flt_rd_dat_i )
);


//---   adler32   ---------------------------------------------
assign adler32_start_w = lz77_start_w ;
adler32 adler32(
  .clk      ( clk               ),
  .rstn     ( rstn              ),
  //
  .start_i  ( start_i           ),
  .val_i    ( fifo_flt_rd_val_o ),
  .dat_i    ( fifo_flt_rd_dat_i ),
  .num_i    (  ),
  .lst_i    (  ),
  //
  .done_o   (  ),
  .val_o    (  ),
  .dat_o    (  )
  );


// lz77 - huffman - bs_top - crc32 - bs_top

//---   huffman   ---------------------------------------------

//---   zlib   ---------------------------------------------
bs_top bs_top(
  clk      ,
  rstn     ,
  //
  start_i  (start_i),
  val_i    ,
  flg_lit_i,
  lit_dat_i,
  len_dat_i,
  dis_dat_i,
  lst_i    ,
  //
  done_o   ,
  val_o    ,
  dat_o
);


//---   crc32   ---------------------------------------------
  crc32 crc32(
  clk    ,
  rstn   ,
  //
  w_i    ,
  h_i    ,
  //
  start_i (start_i),
  val_i  ,
  dat_i  ,
  num_i  ,
  lst_i  ,
  //
  done_o ,
  val_o  ,
  dat_o
  );

  // todo [HBJ]: 
  // 1. top
  // 2. defalte_bitstream - length - adler32 - crc32_IDAT - crc32_IHDR - crc32_IEND
