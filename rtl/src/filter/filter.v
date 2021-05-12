//------------------------------------------------------------------------------
  //
  //  Filename      : filter.v
  //  Description   : filter
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-14
  //
//------------------------------------------------------------------------------
  //  c b
  //  a x
//------------------------------------------------------------------------------

module filter(
    // global
    clk               ,
    rstn              ,
    // cfg_i
    cfg_w_i           ,
    cfg_h_i           ,
    // ctl_if
    start_i           ,
    done_o            ,
    cnt_h_o           ,
    // dat
    val_i             ,
    dat_i             ,
    // fifo_cur
    fifo_cur_wr_val_o ,
    fifo_cur_wr_dat_o ,
    fifo_cur_rd_val_o ,
    fifo_cur_rd_dat_i ,
    // fifo_flt_wr
    fifo_flt_wr_val_o ,
    fifo_flt_wr_dat_o ,
    // fifo_pre_rd
    fifo_pre_rd_val_o ,
    fifo_pre_rd_dat_i 
);


//***   PARAMETER   ***********************************************************
  // global
  // local
  parameter     DATA_THR    = 'd4               ;
  localparam    DATA_CYC    = 'd5               ;

  localparam    FSM_WD      =  'd2              ;
  localparam    IDLE        = 2'd0              ;
  localparam    OPT         = 2'd1              ;  // optimal : do five filters to find the best filter type
  localparam    CMP         = 2'd2              ;  // compare : compare costs of five filter types 
  localparam    FNL         = 2'd3              ;  // final   : filter according to the best filter type

  // derived
  localparam    DATA_CYC_WD = `LOG2( DATA_CYC ) ;


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                                clk               ;
  input                                rstn              ;

  // cfg_i
  input         [`SIZE_W_WD-1   :0]    cfg_w_i           ;  // w -> width
  input         [`SIZE_H_WD-1   :0]    cfg_h_i           ;  // h -> height

  // ctl_if
  input                               start_i            ;
  output                              done_o             ;
  output        [`SIZE_H_WD-1   :0]   cnt_h_o            ;

  // dat
  input                               val_i              ;
  input         [`DATA_PXL_WD-1 :0]   dat_i              ; 

  // fifo_cur
  output                              fifo_cur_wr_val_o  ;  // cur -> current
  output        [`DATA_PXL_WD-1 :0]   fifo_cur_wr_dat_o  ;
  output                              fifo_cur_rd_val_o  ;
  input         [`DATA_PXL_WD-1 :0]   fifo_cur_rd_dat_i  ;

  // fifo_flt_wr
  output                              fifo_flt_wr_val_o  ;  // flt -> filter
  output reg    [`DATA_PXL_WD-1 :0]   fifo_flt_wr_dat_o  ; 

  // fifo_pre_rd
  output                              fifo_pre_rd_val_o  ;  // pre -> previous
  input         [`DATA_PXL_WD-1 :0]   fifo_pre_rd_dat_i  ;
  

//***   WIRE / REG   **********************************************************
  // FSM
  reg           [FSM_WD-1                 :0]    cur_state_r ;  // cur -> current
  reg           [FSM_WD-1                 :0]    nxt_state_w ;  // nxt -> next

  wire                                           opt_done_w  ;
  wire                                           cmp_done_w  ;
  wire                                           fnl_done_w  ;
  wire                                           flg_busy_w  ;

  // counter (opt, fnl)
  reg           [`SIZE_W_WD-1             :0]    cnt_w_r     ;
  reg           [`SIZE_H_WD-1             :0]    cnt_h_r     ;
  wire                                           cnt_w_done_w;
  wire                                           cnt_h_done_w;
  reg           [DATA_CYC_WD-1            :0]    cnt_cmp_r   ;  // cmp -> compare
  wire                                           cnt_cmp_done_w ;

  // dat_a/b/c_r
  wire          [`DATA_PXL_WD-1           :0]    dat_i_w     ;
  reg           [`DATA_PXL_WD-1           :0]    dat_a_r     ;
  reg           [`DATA_PXL_WD-1           :0]    dat_c_r     ;
  wire          [`DATA_PXL_WD-1           :0]    dat_a_w     ;
  wire          [`DATA_PXL_WD-1           :0]    dat_b_w     ;
  wire          [`DATA_PXL_WD-1           :0]    dat_c_w     ;
  wire          [`DATA_PXL_WD+DATA_THR-1  :0]    dat_m_w     ;  // m -> mean
  wire          [`DATA_PXL_WD-1           :0]    dat_p_w     ;  // p -> paeth

  // residual between original pixel and prediction pixel
  wire          [`DATA_PXL_WD-1           :0]    res_0_w     ;
  wire          [`DATA_PXL_WD-1           :0]    res_1_w     ;
  wire          [`DATA_PXL_WD-1           :0]    res_2_w     ;
  wire          [`DATA_PXL_WD-1           :0]    res_3_w     ;
  wire          [`DATA_PXL_WD-1           :0]    res_4_w     ;
  wire          [`DATA_PXL_WD-1           :0]    res_abs_0_w ;
  wire          [`DATA_PXL_WD-1           :0]    res_abs_1_w ;
  wire          [`DATA_PXL_WD-1           :0]    res_abs_2_w ;
  wire          [`DATA_PXL_WD-1           :0]    res_abs_3_w ;
  wire          [`DATA_PXL_WD-1           :0]    res_abs_4_w ;

  // sum of residuals
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_0_w     ;
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_1_w     ;
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_2_w     ;
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_3_w     ;
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_4_w     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_0_r     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_1_r     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_2_r     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_3_r     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_4_r     ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_bst_r   ;
  reg           [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_m_w     ; 
  wire          [`DATA_PXL_WD+`SIZE_W_WD-1:0]    sum_n_w     ; 
  
  // filter types
  reg           [`FILTER_ENUM_WD-1        :0]    typ_bst_r   ;
  reg           [`FILTER_ENUM_WD-1        :0]    typ_m_w     ;
  wire          [`FILTER_ENUM_WD-1        :0]    typ_n_w     ;

//***   MAIN BODY   ***********************************************************
//---   FSM   ---------------------------------------------
  // cur_state_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cur_state_r <= IDLE ;
    end
    else begin
      cur_state_r <= nxt_state_w ;
    end
  end

  // nxt_state_w
  always @(*) begin
                                 nxt_state_w = IDLE ;
    case( cur_state_r )
      IDLE :    if( start_i )    nxt_state_w = OPT  ; else nxt_state_w = IDLE ;
      OPT  :    if( opt_done_w ) nxt_state_w = CMP  ; else nxt_state_w = OPT  ;
      CMP  :    if( cmp_done_w ) nxt_state_w = FNL  ; else nxt_state_w = CMP  ;
      FNL  :    if( fnl_done_w ) nxt_state_w = IDLE ; else nxt_state_w = FNL  ;
    endcase
  end

  // jump condition
  assign cnt_w_done_w   = cnt_w_r == (cfg_w_i - 'd1)           ;
  assign cnt_h_done_w   = cnt_h_r == (cfg_h_i - 'd1)           ;
  assign cnt_cmp_done_w = cnt_cmp_r == (DATA_CYC - 'd1)        ;
  assign opt_done_w     = (cur_state_r==OPT) && cnt_w_done_w   ;
  assign cmp_done_w     = (cur_state_r==CMP) && cnt_cmp_done_w ;
  assign fnl_done_w     = (cur_state_r==FNL) && cnt_w_done_w   ;

  // flg_busy_w
  assign flg_busy_w = (cur_state_r==OPT) || (cur_state_r==FNL) ;

  // fetch previous scanline data
  assign fifo_pre_rd_val_o = (cnt_h_r != 'd0) && flg_busy_w ;

 
//---   COUNTER   -----------------------------------------
  // cnt_w_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_w_r <= 'd0 ;
    end
    else begin
      if( flg_busy_w ) begin
        if( cnt_w_done_w ) cnt_w_r <= 'd0           ;
        else             cnt_w_r <= cnt_w_r + 'd1 ;
      end
    end
  end

  // cnt_h_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_h_r <= 'd0 ;
    end
    else begin
      if( cnt_w_done_w && (cur_state_r==FNL)) begin
        if( cnt_h_done_w ) cnt_h_r <= 'd0           ;
        else               cnt_h_r <= cnt_h_r + 'd1 ;
      end
    end
  end

  // cnt_cmp_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_cmp_r <= 'd0 ;
    end
    else begin
      if( cur_state_r == CMP ) begin
        if( cnt_cmp_done_w ) cnt_cmp_r <= 'd0             ;
        else                 cnt_cmp_r <= cnt_cmp_r + 'd1 ;
      end
    end
  end


// ---   FSM: OPT or FNL   --------------------------------
  // dat_i_w
  assign fifo_cur_rd_val_o = (cur_state_r==FNL)                              ;
  assign dat_i_w           = (cur_state_r==OPT) ? dat_i :  fifo_cur_rd_dat_i ;

  // dat_a/b/c_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dat_a_r <= 'd0 ;
      dat_c_r <= 'd0 ;
    end
    else begin
      if( flg_busy_w ) begin
        dat_a_r <= dat_i_w           ;
        dat_c_r <= fifo_pre_rd_dat_i ;
      end
    end
  end

  // dat_a/b/c_w
  assign dat_a_w = (cnt_w_r=='d0                  ) ? 'd0 : dat_a_r           ;
  assign dat_b_w = (cnt_h_r=='d0                  ) ? 'd0 : fifo_pre_rd_dat_i ;
  assign dat_c_w = (cnt_h_r=='d0 || cnt_w_r  =='d0) ? 'd0 : dat_c_r           ;

  // res_x_w
  //  -----
  // | c b |
  // | a x |
  //  -----
  genvar  gvIdx ;
  generate
    for( gvIdx = 'd0; gvIdx < DATA_THR; gvIdx = gvIdx + 'd1 ) begin : res
      // res_x_w
        // None
        assign res_0_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = dat_i_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ;
        // Sub a
        assign res_1_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = dat_i_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] - 
                                                             dat_a_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ;
        // Sub b
        assign res_2_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = dat_i_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] - 
                                                             dat_b_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ;
        // Sub (a+b)/2
        assign dat_m_w[(`DATA_CHN_WD+1)*gvIdx +: (`DATA_CHN_WD+1)] = (dat_a_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] +
                                                                      dat_b_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ) >> 1;
        assign res_3_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = dat_i_w[ `DATA_CHN_WD   *gvIdx +: `DATA_CHN_WD] - 
                                                             dat_m_w[(`DATA_CHN_WD+1)*gvIdx +: `DATA_CHN_WD] ;
        // Sub pathe(a, b, c)
        assign res_4_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = dat_i_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] - 
                                                             dat_p_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ;
        filter_paeth #(
          .DATA_WD ( `DATA_CHN_WD                                )
        )filter_paeth(
          .dat_a_i ( dat_a_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ),
          .dat_b_i ( dat_b_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ),
          .dat_c_i ( dat_c_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] ),
          .dat_o   ( dat_p_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] )
        );

      // res_abs_x_w
        assign res_abs_0_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = res_0_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD]         ;
        assign res_abs_1_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = res_1_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] < 'd128 ?
                                                                 res_1_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD]         :
                                                               - res_1_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] + 'd255 ;
        assign res_abs_2_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = res_2_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] < 'd128 ?
                                                                 res_2_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD]         :
                                                               - res_2_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] + 'd255 ;
        assign res_abs_3_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = res_3_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] < 'd128 ?
                                                                 res_3_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD]         :
                                                               - res_3_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] + 'd255 ;
        assign res_abs_4_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] = res_4_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] < 'd128 ?
                                                                 res_4_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD]         :
                                                               - res_4_w[`DATA_CHN_WD*gvIdx +: `DATA_CHN_WD] + 'd255 ;
    end 
  endgenerate


// ---   FSM: OPT   ---------------------------------------
  // fifo_cur_wr
  assign fifo_cur_wr_val_o = val_i ;
  assign fifo_cur_wr_dat_o = dat_i ;

  // sum_x_w
  assign sum_0_w = (cnt_w_r == 'd0) ? 'd0 : sum_0_r;
  assign sum_1_w = (cnt_w_r == 'd0) ? 'd0 : sum_1_r;
  assign sum_2_w = (cnt_w_r == 'd0) ? 'd0 : sum_2_r;
  assign sum_3_w = (cnt_w_r == 'd0) ? 'd0 : sum_3_r;
  assign sum_4_w = (cnt_w_r == 'd0) ? 'd0 : sum_4_r;

  // sum_x_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      sum_0_r <= 'd0 ;
      sum_1_r <= 'd0 ;
      sum_2_r <= 'd0 ;
      sum_3_r <= 'd0 ;
      sum_4_r <= 'd0 ;
    end
    else begin
      if( cur_state_r == OPT ) begin
        sum_0_r <= sum_0_w + res_abs_0_w[0 +:8] + res_abs_0_w[8 +:8] + res_abs_0_w[16 +:8] + res_abs_0_w[24 +:8] ;
        sum_1_r <= sum_1_w + res_abs_1_w[0 +:8] + res_abs_1_w[8 +:8] + res_abs_1_w[16 +:8] + res_abs_1_w[24 +:8] ;
        sum_2_r <= sum_2_w + res_abs_2_w[0 +:8] + res_abs_2_w[8 +:8] + res_abs_2_w[16 +:8] + res_abs_2_w[24 +:8] ;
        sum_3_r <= sum_3_w + res_abs_3_w[0 +:8] + res_abs_3_w[8 +:8] + res_abs_3_w[16 +:8] + res_abs_3_w[24 +:8] ;
        sum_4_r <= sum_4_w + res_abs_4_w[0 +:8] + res_abs_4_w[8 +:8] + res_abs_4_w[16 +:8] + res_abs_4_w[24 +:8] ;
      end
    end
  end


// ---   FSM: CMP (Compare)   -----------------------------
  // bst_type_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      typ_bst_r <= 'd0 ;
      sum_bst_r <= 'd0 ;
    end
    else begin
      if( cur_state_r == CMP ) begin
        if( sum_m_w < sum_n_w ) begin
          typ_bst_r <= typ_m_w ;
          sum_bst_r <= sum_m_w ;
        end
        else begin
          typ_bst_r <= typ_n_w ;
          sum_bst_r <= sum_n_w ;
        end
      end
    end
  end

  // typ/sum_m_w
  always @(*) begin
                    typ_m_w = 'd0 ; sum_m_w = 'd0     ;
    case( cnt_cmp_r )
      'd0 : begin   typ_m_w = 'd1 ; sum_m_w = sum_1_r ; end
      'd1 : begin   typ_m_w = 'd2 ; sum_m_w = sum_2_r ; end
      'd2 : begin   typ_m_w = 'd3 ; sum_m_w = sum_3_r ; end
      'd3 : begin   typ_m_w = 'd4 ; sum_m_w = sum_4_r ; end
      'd4 : begin   typ_m_w = 'd4 ; sum_m_w = sum_4_r ; end  // redundant logic for exporting best filter type
    endcase
  end

  // typ/sum_n_w
  assign typ_n_w = (cnt_cmp_r=='d0) ?     'd0 : typ_bst_r ;
  assign sum_n_w = (cnt_cmp_r=='d0) ? sum_0_r : sum_bst_r ;


// ---   FSM: FNL   ---------------------------------------
  // fifo_flt_wr_val_o
  assign fifo_flt_wr_val_o = cnt_cmp_done_w || (cur_state_r==FNL) ;

  // fifo_flt_wr_dar_o
  always @(*) begin
              fifo_flt_wr_dat_o = 'd0         ;
    if( cnt_cmp_done_w ) begin
              fifo_flt_wr_dat_o = typ_bst_r << 24;
    end
    else if( cur_state_r==FNL ) begin
      case( typ_bst_r )
        'd0 : fifo_flt_wr_dat_o = res_0_w ;
        'd1 : fifo_flt_wr_dat_o = res_1_w ;
        'd2 : fifo_flt_wr_dat_o = res_2_w ;
        'd3 : fifo_flt_wr_dat_o = res_3_w ;
        'd4 : fifo_flt_wr_dat_o = res_4_w ;
      endcase
    end
  end

  // done_o
  assign done_o = (cur_state_r==FNL) && (nxt_state_w==IDLE) ;

  // cnt_h_o
  assign cnt_h_o = cnt_h_r ;

endmodule
