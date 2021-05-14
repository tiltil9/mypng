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
    dat_o
);

//***   PARAMETER   ***********************************************************
  // global
  localparam    DATA_THR = 'd4 ;
  localparam    DATA_WD  = 'd32;
  localparam    NUM_WD   = 'd2 ;
  localparam    LIT_DAT_WD  = 'd8 ;
  localparam    LEN_DAT_WD  = 'd7 ;
  localparam    DIS_DAT_WD  = 'd7 ;

  // derived
  localparam    DATA_THR_WD = `LOG2( DATA_THR ) ;

//***   INPUT / OUTPUT   ******************************************************
  // global
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
  output                              val_o              ;
  output        [`DATA_PXL_WD-1 :0]   dat_o              ;


//***   WIRE / REG   **********************************************************
  reg                                 lz77_start_r              ;

// filter
  wire                                filter_start_i            ;
  wire                                filter_done_o             ;

  wire                                filter_val_i              ;
  wire          [`DATA_PXL_WD-1 :0]   filter_dat_i              ;

  wire                                filter_fifo_flt_wr_val_o  ;
  wire          [`DATA_PXL_WD-1 :0]   filter_fifo_flt_wr_dat_o  ;

// fifo
  wire                                 fifo_flt_wr_val_i  ;
  wire          [`DATA_PXL_WD-1:0]     fifo_flt_wr_dat_i  ;
  wire                                 fifo_flt_rd_val_i  ;
  wire          [`DATA_PXL_WD-1:0]     fifo_flt_rd_dat_o  ;

// lz77
  wire                                 lz77_start_i           ;
  wire                                 lz77_done_o            ;
  wire                                 lz77_val_o             ;
  wire                                 lz77_flg_lit_o         ;  // flg -> flag ; lit -> literal
  wire          [`DATA_CHN_WD-1 :0]    lz77_dat_lit_o         ;
  wire          [`SIZE_LEN_WD-1 :0]    lz77_dat_len_o         ;  // len -> length
  wire          [`SIZE_DST_WD-1 :0]    lz77_dat_dst_o         ;  // dst -> distance
  wire                                 lz77_flg_lst_o         ;  // lst -> last
  wire                                 lz77_fifo_flt_rd_val_o ;  // flt -> filter ; rd -> read
  wire          [`DATA_PXL_WD-1 :0]    lz77_fifo_flt_rd_dat_i ;
  wire                                 lz77_adler32_val_o     ;
  wire          [`DATA_PXL_WD-1 :0]    lz77_adler32_dat_o     ;
  wire          [DATA_THR_WD -1 :0]    lz77_adler32_num_o     ; // means 1/2/3/4 most significant bytes are valid
  wire                                 lz77_adler32_lst_o     ;

// adler32
  wire                                 adler32_start_i             ;
  wire                                 adler32_val_i               ;
  wire       [DATA_WD           -1 :0] adler32_dat_i               ;
  wire       [NUM_WD            -1 :0] adler32_num_i               ; // means 1/2/3/4 most significant bytes are valid
  wire                                 adler32_lst_i               ;
  wire                                 adler32_done_o              ;
  wire                                 adler32_val_o               ;
  wire       [DATA_WD           -1 :0] adler32_dat_o               ;


// bs
  wire                                 bs_start_i            ;
  wire                                 bs_val_i              ;
  wire                                 bs_flg_lit_i          ;
  wire   [LIT_DAT_WD  -1 :0]           bs_lit_dat_i          ;
  wire   [LEN_DAT_WD  -1 :0]           bs_len_dat_i          ;
  wire   [DIS_DAT_WD  -1 :0]           bs_dis_dat_i          ;
  wire                                 bs_lst_i              ;
  wire                                 bs_done_o             ;
  wire                                 bs_val_o              ;
  wire   [DATA_WD     -1 :0]           bs_dat_o              ;

// crc32
  wire                                 crc32_start_i          ;
  wire                                 crc32_val_i            ;
  wire   [NUM_WD      -1 :0]           crc32_num_i            ;
  wire                                 crc32_lst_i            ;
  wire                                 crc32_done_o           ;
  wire                                 crc32_val_o            ;
  wire   [DATA_WD     -1 :0]           crc32_dat_o            ;

//***   MAIN BODY   ***********************************************************
//---   top   ------------------------------------------------
  assign val_o  = bs_val_o ;
  assign dat_o  = bs_dat_o ;
  assign done_o = bs_done_o ;

  // lz77_start_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      lz77_start_r <= 'd0 ;
    end
    else begin
      lz77_start_r <= lz77_start_i ;
    end
  end

//---   filter   ---------------------------------------------
// todo: req
  assign filter_start_i = start_i ;
  assign filter_val_i   = val_i   ;  
  assign filter_dat_i   = dat_i   ; 

  filter_top filter_top(
      // global
      .clk               ( clk                      ),
      .rstn              ( rstn                     ),
      // cfg_i
      .cfg_w_i           ( cfg_w_i                  ),
      .cfg_h_i           ( cfg_h_i                  ),
      // ctl_if
      .start_i           ( filter_start_i           ),
      .done_o            ( filter_done_o            ),
      // dat
      .val_i             ( filter_val_i             ),
      .dat_i             ( filter_dat_i             ),
      // fifo_flt_wr
      .fifo_flt_wr_val_o ( filter_fifo_flt_wr_val_o ),
      .fifo_flt_wr_dat_o ( filter_fifo_flt_wr_dat_o )
  );


//---   fifo_flt   ---------------------------------------------
  assign fifo_flt_wr_val_i = filter_fifo_flt_wr_val_o ;
  assign fifo_flt_wr_dat_i = filter_fifo_flt_wr_dat_o ;
  assign fifo_flt_rd_val_i = lz77_fifo_flt_rd_val_o   ;
  assign lz77_fifo_flt_rd_dat_i = fifo_flt_rd_dat_o   ;

  fifo #(
      .SIZE        (`SIZE_W_MAX+'d1    ),
      .DATA_WD     (`DATA_PXL_WD       )
  )fifo_flt(
      // global
      .clk         ( clk               ),
      .rstn        ( rstn              ),
      // cfg 
      .cfg_w_i     ( cfg_w_i           ),
      // write
      .wr_val_i    ( fifo_flt_wr_val_i ),
      .wr_dat_i    ( fifo_flt_wr_dat_i ),
      // read
      .rd_ack_i    ( fifo_flt_rd_val_i ),
      .rd_dat_o    ( fifo_flt_rd_dat_o )
  );


//---   lz77   ---------------------------------------------
  assign lz77_start_i = filter_done_o ;

  lz77_top lz77_top(
      // global
      .clk               ( clk                    ),
      .rstn              ( rstn                   ),
      // cfg_i
      .cfg_w_i           ( cfg_w_i                ),
      .cfg_h_i           ( cfg_h_i                ),
      // ctl_if
      .start_i           ( lz77_start_r           ),
      .done_o            ( lz77_done_o            ),
      // dat
      .val_o             ( lz77_val_o             ),
      .flg_lit_o         ( lz77_flg_lit_o         ),
      .dat_lit_o         ( lz77_dat_lit_o         ),
      .dat_len_o         ( lz77_dat_len_o         ),
      .dat_dst_o         ( lz77_dat_dst_o         ),
      .flg_lst_o         ( lz77_flg_lst_o         ),
      // fifo_flt_rd
      .fifo_flt_rd_val_o ( lz77_fifo_flt_rd_val_o ),
      .fifo_flt_rd_dat_i ( lz77_fifo_flt_rd_dat_i ),
      // adler32
      .adler32_val_o     ( lz77_adler32_val_o     ),
      .adler32_dat_o     ( lz77_adler32_dat_o     ),
      .adler32_num_o     ( lz77_adler32_num_o     ),
      .adler32_lst_o     ( lz77_adler32_lst_o     )

  );


//---   adler32   ---------------------------------------------
  assign adler32_start_i = start_i            ;
  assign adler32_val_i   = lz77_adler32_val_o ;
  assign adler32_dat_i   = lz77_adler32_dat_o ;
  assign adler32_num_i   = lz77_adler32_num_o ;
  assign adler32_lst_i   = lz77_adler32_lst_o ;

  adler32 adler32(
    .clk      ( clk               ),
    .rstn     ( rstn              ),
    //
    .start_i  ( adler32_start_i   ),
    .val_i    ( adler32_val_i     ),
    .dat_i    ( adler32_dat_i     ),
    .num_i    ( adler32_num_i     ),
    .lst_i    ( adler32_lst_i     ),
    //
    .done_o   ( adler32_done_o    ),
    .val_o    ( adler32_val_o     ),
    .dat_o    ( adler32_dat_o     )
    );


//---   bs   ---------------------------------------------
  assign bs_start_i   = start_i       ;
  assign bs_val_i     = lz77_val_o    ;
  assign bs_flg_lit_i = lz77_flg_lit_o;
  assign bs_lit_dat_i = lz77_dat_lit_o;
  assign bs_len_dat_i = lz77_dat_len_o;
  assign bs_dis_dat_i = lz77_dat_dst_o;
  assign bs_lst_i     = lz77_flg_lst_o;

  bs_top bs_top(
    .clk             ( clk          ),
    .rstn            ( rstn         ),
    //
    .start_i         ( bs_start_i   ),
    .val_i           ( bs_val_i     ),
    .flg_lit_i       ( bs_flg_lit_i ),
    .lit_dat_i       ( bs_lit_dat_i ),
    .len_dat_i       ( bs_len_dat_i ),
    .dis_dat_i       ( bs_dis_dat_i ),
    .lst_i           ( bs_lst_i     ),
    //
    .adler32_done_i  ( adler32_done_o ),
    .adler32_dat_i   ( adler32_dat_o ),
    //
    .crc32_val_o     ( crc32_val_i  ),
    .crc32_num_o     ( crc32_num_i  ),
    .crc32_lst_o     ( crc32_lst_i  ),
    .crc32_done_i    ( crc32_done_o ),
    .crc32_val_i     ( crc32_val_o  ),
    .crc32_dat_i     ( crc32_dat_o  ),
    //
    .done_o          ( bs_done_o    ),
    .val_o           ( bs_val_o     ),
    .dat_o           ( bs_dat_o     )
  );


//---   crc32   ---------------------------------------------
  assign crc32_start_i = start_i;

  crc32_top crc32(
  .clk      ( clk           ),
  .rstn     ( rstn          ),
  //
  .w_i      ( cfg_w_i       ),
  .h_i      ( cfg_h_i       ),
  //
  .start_i  ( crc32_start_i ),
  .val_i    ( crc32_val_i   ),
  .dat_i    ( bs_dat_o      ),
  .num_i    ( crc32_num_i   ),
  .lst_i    ( crc32_lst_i   ),
  //
  .done_o   ( crc32_done_o  ),
  .val_o    ( crc32_val_o   ),
  .dat_o    ( crc32_dat_o   )
  );


endmodule