//------------------------------------------------------------------------------
  //
  //  Filename      : lz77_top.v
  //  Description   : lz77 sliding window compress + fixed huffman encoding
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-05-2
  //
//------------------------------------------------------------------------------

module lz77_top(
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
    val_o             ,
    flg_lit_o         ,
    dat_lit_o         ,
    dat_len_o         ,
    dat_dst_o         ,
    flg_lst_o         ,
    // fifo_flt_rd
    fifo_flt_rd_val_o ,
    fifo_flt_rd_dat_i ,
    // adler32
    adler32_val_o     ,
    adler32_dat_o     ,
    adler32_num_o     ,
    adler32_lst_o
);


//***   PARAMETER   ***********************************************************
  // global
  localparam    DATA_THR    = 'd4                               ;
  localparam    DLY         = 'd4                               ;

  // local
  localparam    FSM_WD      =  'd3                              ;
  localparam    IDLE        = 3'b001                            ;
  localparam    UPT         = 3'b010                            ;  // upt -> update : update input and sliding window
  localparam    SCH         = 3'b100                            ;  // sch -> search : search the best length and distance

  localparam    SIZE_INP_MAX   = `SIZE_LEN_MAX + DATA_THR - 'd1 ;
  localparam    SIZE_ALL_MAX   = `SIZE_DST_MAX + SIZE_INP_MAX   ;


  // derived
  localparam    SIZE_INP_WD      = `LOG2( SIZE_INP_MAX     )    ;  // inp -> input
  localparam    SIZE_ALL_WD      = `LOG2( SIZE_ALL_MAX     )    ;  // inp -> input
  
  localparam    SIZE_CYC_SCH_MAX = `SIZE_LEN_MAX                ;
  localparam    SIZE_CYC_SCH_WD  = `LOG2( SIZE_CYC_SCH_MAX )    ;
  
  localparam    DATA_THR_WD      = `LOG2( DATA_THR         )    ;


//***   INPUT / OUTPUT   ******************************************************
  // global
  input                                clk               ;
  input                                rstn              ;

  // cfg_i
  input         [`SIZE_W_WD-1   :0]    cfg_w_i           ;  // w -> width
  input         [`SIZE_H_WD-1   :0]    cfg_h_i           ;  // h -> height

  // ctl_if
  input                                start_i           ;
  output reg                           done_o            ;

  // dat
  output reg                           val_o             ;
  output reg                           flg_lst_o         ;  // lst -> last
  output                               flg_lit_o         ;  // flg -> flag ; lit -> literal
  output        [`DATA_CHN_WD-1 :0]    dat_lit_o         ;
  output        [`SIZE_LEN_WD-1 :0]    dat_len_o         ;  // len -> length
  output        [`SIZE_DST_WD-1 :0]    dat_dst_o         ;  // dst -> distance

  // fifo_pre_rd
  output reg                           fifo_flt_rd_val_o ;  // flt -> filter ; rd -> read
  input         [`DATA_PXL_WD-1 :0]    fifo_flt_rd_dat_i ;

  // adler32
  output                               adler32_val_o     ;
  output        [`DATA_PXL_WD-1 :0]    adler32_dat_o     ;
  output        [DATA_THR_WD -1 :0]    adler32_num_o     ; // means 1/2/3/4 most significant bytes are valid
  output                               adler32_lst_o     ;
  

//***   WIRE / REG   **********************************************************
  // FSM
  reg           [FSM_WD-1                 :0]    cur_state_r         ;  // cur -> current
  reg           [FSM_WD-1                 :0]    nxt_state_w         ;  // nxt -> next
  wire                                           flg_idle_w          ;
  wire                                           flg_upt_w           ;
  wire                                           flg_sch_w           ;

  reg           [DLY-1                    :0]    start_dly_r         ;
  wire                                           fifo_flt_rd_val_w   ;  // flt -> filter ; rd -> read
  reg                                            fifo_flt_rd_val_o_r ;  // flt -> filter ; rd -> read

  // counter (upt, sch)
  reg           [`SIZE_W_WD+`SIZE_H_WD-1  :0]    cnt_i_r             ;  // cnt -> count

  wire          [`SIZE_W_WD+`SIZE_H_WD-1  :0]    cnt_o_w             ;
  reg           [`SIZE_W_WD+`SIZE_H_WD-1  :0]    cnt_o_r             ;

  reg           [`SIZE_H_WD-1             :0]    cnt_h_o_r           ;
  wire                                           cnt_h_o_done_w      ;

  reg           [SIZE_INP_WD+2-1          :0]    cnt_upt_r           ;  // upt -> update
  wire                                           cnt_upt_done_w      ;
  reg                                            cnt_upt_done_r      ;
  reg                                            cnt_upt_done_d1_r   ;
  wire                                           upt_done_w          ;
  wire                                           flg_fst_upt_w       ;  // flg -> flag ; fst -> first

  reg           [SIZE_CYC_SCH_WD-1        :0]    cnt_sch_r           ;  // sch -> search
  wire                                           cnt_sch_done_w      ;
  wire                                           sch_done_w          ;
  wire                                           flg_fst_sch_w       ;  // flg -> flag ; fst -> first

  wire                                           flg_skp_sch_w       ;  // skp -> skip
  wire                                           flg_lin_done_w      ;
  wire                                           flg_pic_done_w      ;


  // sliding window
  wire          [`DATA_CHN_WD*`SIZE_DST_MAX-1:0] dat_win_w           ;  // win -> sliding window
  wire          [`DATA_CHN_WD*`SIZE_DST_MAX-1:0] dat_win_shift_w     ;
  reg           [`DATA_CHN_WD*`SIZE_DST_MAX-1:0] dat_win_r           ;
  reg           [`SIZE_DST_WD                :0] len_win_r           ;

  // input
  wire          [`DATA_CHN_WD* SIZE_INP_MAX-1:0] dat_inp_w                  ;  // inp -> input
  reg           [`DATA_CHN_WD* SIZE_INP_MAX-1:0] dat_inp_r                  ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_w                  ;
  reg  signed   [ SIZE_INP_WD                :0] len_inp_r                  ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_mux_w              ;  // mux -> multiplexer

  wire          [`SIZE_W_WD+`SIZE_H_WD-1  :0   ] len_lin_rst_w              ;  // len -> length ; lin -> line ; rst -> rest
  wire          [`SIZE_W_WD+`SIZE_H_WD-1  :0   ] len_lins_w                 ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_dlt_w              ;  // dlt -> delta
  wire signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_w         ;
  reg  signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_r         ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_mux_w     ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_min_w     ;
  reg  signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_min_r     ;
  wire signed   [ SIZE_INP_WD                :0] len_inp_dlt_ceil_min_mux_w ;
  
  // all
  reg           [`DATA_CHN_WD* SIZE_ALL_MAX-1:0] dat_all_r                  ;  // all -> sliding window + input

  // search
  wire          [`SIZE_LEN_MAX-1             :0] flg_mat_w                  ;  // mat -> match
  reg           [`SIZE_LEN_MAX-1             :0] flg_mat_r                  ;


  wire                                           flg_lit_w                  ;
  reg                                            flg_lit_r                  ;
  reg           [`DATA_CHN_WD-1              :0] dat_lit_r                  ;

  wire          [`SIZE_LEN_WD-1              :0] bst_len_w                  ;
  reg           [`SIZE_LEN_WD-1              :0] bst_len_r                  ;
  wire          [`SIZE_DST_WD-1              :0] bst_dst_w                  ;
  reg           [`SIZE_DST_WD-1              :0] bst_dst_r                  ;

  wire                                           val_w                      ;
  wire                                           done_w                     ;
  wire                                           flg_lst_w                  ;

  // adler32
  reg           [`SIZE_W_WD+`SIZE_H_WD-1     :0] cnt_fifo_i_r               ;  // cnt -> count
  wire          [`SIZE_W_WD+`SIZE_H_WD-1     :0] cnt_fifo_i_w               ;
  wire                                           cnt_fifo_done_w            ;


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
      IDLE :  nxt_state_w = start_i ? UPT : IDLE ;
      UPT  :  nxt_state_w = upt_done_w ? (flg_skp_sch_w  ? IDLE : SCH) : UPT ;
      SCH  :  nxt_state_w = sch_done_w ? (flg_pic_done_w ? IDLE : UPT) : SCH ;
    endcase
  end

  // flg_state_w
  assign {flg_sch_w , flg_upt_w, flg_idle_w} = cur_state_r ;

  // count done
  assign cnt_h_o_done_w = cnt_h_o_r   == (cfg_h_i - 'd1)                          ;
  assign cnt_upt_done_w = cnt_upt_r == (len_inp_dlt_ceil_min_mux_w * DATA_THR)    ; // ONE CYCLE FOR SHIFT INPUT
  assign cnt_sch_done_w = cnt_sch_r == (len_win_r == 'd0 ? 'd0 : len_win_r - 'd1) ;

  //  jump condition 
  assign upt_done_w     = flg_upt_w && cnt_upt_done_d1_r ;
  assign sch_done_w     = flg_sch_w && (cnt_sch_done_w || (flg_mat_r == 'd0)) ; // early end when flg_mat_r=0

  assign len_lins_w    = cfg_w_i * DATA_THR + 'd1 ;
  assign len_lin_rst_w = len_lins_w - cnt_i_r     ;

  assign flg_skp_sch_w  = !cnt_h_o_done_w && (len_inp_dlt_ceil_mux_w > len_lin_rst_w) ; // do not skip the last scanline
  assign flg_lin_done_w = flg_sch_w && (cnt_o_w == len_lins_w) ;
  assign flg_pic_done_w = flg_lin_done_w && cnt_h_o_done_w && (len_lin_rst_w=='d0) ;

  // flg_fst_upt/sch_w
  assign flg_fst_upt_w =  flg_upt_w && (cnt_upt_r=='d0) ;
  assign flg_fst_sch_w =  flg_sch_w && (cnt_sch_r=='d0) ;

  // fetch filter scanline 
  assign fifo_flt_rd_val_w =  (flg_upt_w && !cnt_upt_done_w && !cnt_upt_done_r && !cnt_upt_done_d1_r) &&
                              (start_dly_r[0] || ((cnt_upt_r - DATA_THR) % (DATA_THR*DATA_THR) =='d0)) ;


//---   DELAY   -----------------------------------------
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      start_dly_r         <= 'd0 ;
      done_o              <= 'd0 ;
      val_o               <= 'd0 ;
      flg_lst_o           <= 'd0 ;
      cnt_fifo_i_r        <= 'd0 ;
      fifo_flt_rd_val_o   <= 'd0 ;
      fifo_flt_rd_val_o_r <= 'd0 ;
      cnt_upt_done_r      <= 'd0 ;
      cnt_upt_done_d1_r   <= 'd0 ;
    end
    else begin
      start_dly_r         <= {start_dly_r , start_i}     ;
      done_o              <= done_w                      ;
      val_o               <= val_w                       ;
      flg_lst_o           <= flg_lst_w                   ;
      cnt_fifo_i_r        <= cnt_fifo_i_w                ;
      fifo_flt_rd_val_o   <= fifo_flt_rd_val_w           ;
      fifo_flt_rd_val_o_r <= fifo_flt_rd_val_o           ;
      cnt_upt_done_r      <= flg_upt_w && cnt_upt_done_w ;
      cnt_upt_done_d1_r   <= flg_upt_w && cnt_upt_done_r ;
    end
  end


//---   COUNTER   -----------------------------------------
  // cnt_upt_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_upt_r <= 'd0 ;
    end
    else begin
      if( flg_upt_w && !cnt_upt_done_r && !cnt_upt_done_d1_r) begin
        if( cnt_upt_done_w ) begin 
          cnt_upt_r <= 'd0 ;
        end
        else begin
          cnt_upt_r <= cnt_upt_r + ( start_dly_r ? 'd1 : DATA_THR) ;
        end
      end
    end
  end

  // cnt_sch_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_sch_r <= 'd0 ;
    end
    else begin
      if( flg_sch_w ) begin
        if( sch_done_w ) cnt_sch_r <= 'd0             ;
        else             cnt_sch_r <= cnt_sch_r + 'd1 ;
      end
    end
  end

  assign cnt_o_w = cnt_o_r + (flg_lit_w ? bst_len_r : cnt_sch_r + 'd1);

  // cnt_o_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_o_r <= 'd0 ;
    end
    else begin
      if( val_o ) begin
        cnt_o_r <= `MOD(cnt_o_r + dat_len_o, len_lins_w) ;
      end
    end
  end

  // cnt_h_o_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_h_o_r <= 'd0 ;
    end
    else begin
      if( done_o ) begin
        if( cnt_h_o_done_w ) cnt_h_o_r <= 'd0             ;
        else                 cnt_h_o_r <= cnt_h_o_r + 'd1 ;
      end
    end
  end


// ---   FSM: UPDATE   -------------------------------- 
  // ---- len ---------------------
  // len_inp_dlt_w
  assign len_inp_dlt_w              = `SIZE_LEN_MAX + dat_len_o - len_inp_r                                                            ;
  assign len_inp_dlt_ceil_w         = (len_inp_dlt_w % DATA_THR == start_dly_r[0]) ? len_inp_dlt_w : `CEIL(len_inp_dlt_w, DATA_THR) + start_dly_r[0] ; // start_r == 'd1 : fetch type, fetch 1 or 4n + 1
  assign len_inp_dlt_ceil_mux_w     = flg_fst_upt_w ? len_inp_dlt_ceil_w : len_inp_dlt_ceil_r                                          ;
  assign len_inp_dlt_ceil_min_w     = `MIN2(len_inp_dlt_ceil_w, len_lin_rst_w)                                                         ;
  assign len_inp_dlt_ceil_min_mux_w = flg_fst_upt_w ? len_inp_dlt_ceil_min_w : len_inp_dlt_ceil_min_r                                  ;

  // len_inp_w
  assign len_inp_w              = len_inp_r - dat_len_o + len_inp_dlt_ceil_min_w ;
  assign len_inp_mux_w          = flg_fst_upt_w ? len_inp_w : len_inp_r          ;

  // len_inp_*_r / len_win_r / cnt_i_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      len_inp_dlt_ceil_r     <= 'd0 ;
      len_inp_dlt_ceil_min_r <= 'd0 ;
      len_inp_r              <= 'd0 ;
      len_win_r              <= 'd0 ;
      cnt_i_r                <= 'd0 ;
    end
    else begin
      if( flg_fst_upt_w ) begin
        len_inp_dlt_ceil_r     <= len_inp_dlt_ceil_w     ;
        len_inp_dlt_ceil_min_r <= len_inp_dlt_ceil_min_w ;
        len_inp_r              <= len_inp_w              ;
        len_win_r              <= `MIN2(len_win_r + dat_len_o, `SIZE_DST_MAX) ;
        cnt_i_r                <= cnt_i_r + len_inp_dlt_ceil_min_mux_w        ;
      end
      if( done_o ) begin
        cnt_i_r <= `MOD(cnt_i_r, len_lins_w) ;
      end
    end
  end

  // ---- dat ---------------------
  // dat_all_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dat_all_r <= 'd0 ;
    end
    else begin
      if( fifo_flt_rd_val_o_r ) begin
        if( start_dly_r[2] ) begin
          dat_all_r <= {dat_all_r, fifo_flt_rd_dat_i[DATA_THR*`DATA_CHN_WD-'d1 -:`DATA_CHN_WD]} ;
        end
        else begin
          dat_all_r <= {dat_all_r, fifo_flt_rd_dat_i} ;
        end
      end
    end
  end

  // dat_win/inp_w
  assign {dat_win_w, dat_inp_w} = dat_all_r ;

  // dat_inp_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dat_inp_r <= 'd0 ;
    end
    else begin
      if( upt_done_w ) begin
        dat_inp_r <= dat_inp_w << (SIZE_INP_MAX - len_inp_mux_w)*`DATA_CHN_WD;
      end
    end
  end

  // dat_win_shift_w
  assign dat_win_shift_w = (dat_win_w << (SIZE_INP_MAX - len_inp_mux_w)*`DATA_CHN_WD) + 
                           (dat_inp_w >> (               len_inp_mux_w)*`DATA_CHN_WD) ;

  // dat_win_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dat_win_r <= 'd0 ;
    end
    else begin
      if( upt_done_w ) begin
        dat_win_r <= dat_win_shift_w ;
      end
    end
  end


// ---   FSM: SCH   ---------------------------------------
  // ---- mat -----------------------------------
  // flg_mat_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      flg_mat_r <= 'd0 ;
    end
    else begin
      if ( upt_done_w ) begin
        flg_mat_r <= ('d1 << `SIZE_LEN_MAX) - 'd1 ;
      end
      else if( flg_sch_w ) begin
        flg_mat_r <= flg_mat_w ;
      end
    end
  end

  // flg_mat_w
  genvar  gvIdx ;
  generate
    for( gvIdx = 'd0; gvIdx < `SIZE_LEN_MAX; gvIdx = gvIdx + 'd1 ) begin : flg_mat
      assign flg_mat_w[gvIdx] = gvIdx < cnt_sch_r ? 'd0 :
                                (flg_mat_r[gvIdx] & 
                                (dat_inp_r[(SIZE_INP_MAX - cnt_sch_r) * `DATA_CHN_WD -'d1 -: `DATA_CHN_WD] ==
                                 dat_win_r[(gvIdx        - cnt_sch_r) * `DATA_CHN_WD      +: `DATA_CHN_WD] ));
    end 
  endgenerate

  // ---- (distance, length) / literal ----------
  // bst_dst_w
  lz77_detect_one lz77_detect_one(
    .dat_i ( flg_mat_w ) ,
    .pos_o ( bst_dst_w )
  );

  // bst_len_w
  assign bst_len_w = cnt_sch_r + 'd1;

  // flg_lit_w
  assign flg_lit_w = (bst_dst_w >  len_win_r                      ) ||
                     (bst_len_w >  `MIN2(len_inp_r, `SIZE_LEN_MAX)) ||
                     (bst_len_w <  `SIZE_LEN_MIN                  )  ;

  // flg/dat_lit_r / bst_len / dst_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      flg_lit_r <= 'd0 ;
      bst_len_r <= 'd0 ;
      bst_dst_r <= 'd0 ;
      dat_lit_r <= 'd0 ;
    end
    else begin
      if( flg_sch_w ) begin
        if( flg_fst_sch_w ) begin
          flg_lit_r <= 'd1 ;
          bst_len_r <= 'd1 ;
          bst_dst_r <= 'd1 ;
          dat_lit_r <= dat_inp_r[SIZE_INP_MAX*`DATA_CHN_WD - 'd1 -: `DATA_CHN_WD]  ;
        end
        else begin
          flg_lit_r <= flg_lit_w ? flg_lit_r : 'd0;
          bst_len_r <= flg_lit_w ? bst_len_r : (cnt_sch_r + 'd1) ;
          bst_dst_r <= flg_lit_w ? bst_dst_r : bst_dst_w;
        end
      end
    end
  end


// ---   OUTPUT   ---------------------------------------
  // ---- lz77 output ---------------------------
  // val/done/flg_lst_w
  assign val_w = (cur_state_r==SCH ) && (nxt_state_w!=SCH) ;
  assign done_w = (cur_state_r!=IDLE) && (nxt_state_w==IDLE) ;
  assign flg_lst_w = (cur_state_r==SCH) && (nxt_state_w==IDLE) ;

  // lz77
  assign flg_lit_o = val_o ? flg_lit_r : 'd0 ;
  assign dat_lit_o = val_o ? dat_lit_r : 'd0 ;
  assign dat_len_o = val_o ? bst_len_r : 'd0 ;
  assign dat_dst_o = val_o ? bst_dst_r : 'd0 ;

  // ---- adler32 output ------------------------
  // cnt_fifo_w
  assign cnt_fifo_i_w    = cnt_fifo_i_r + fifo_flt_rd_val_o_r          ;
  assign cnt_fifo_done_w = cnt_fifo_i_w == (cfg_h_i * (cfg_w_i + 'd1)) ;

  // adler32
  assign adler32_val_o = fifo_flt_rd_val_o_r          ;
  assign adler32_dat_o = fifo_flt_rd_dat_i            ;
  assign adler32_num_o = start_dly_r[2] ? 'd0 : DATA_THR-'d1 ;
  assign adler32_lst_o =  cnt_fifo_done_w             ;

endmodule
