//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module bs_top(
  clk           ,
  rstn          ,
  //
  start_i       ,
  val_i         ,
  flg_lit_i     ,
  lit_dat_i     ,
  len_dat_i     ,
  dis_dat_i     ,
  lst_i         ,
  //
  adler32_done_i,
  adler32_dat_i ,
  //
  crc32_val_o   ,
  crc32_num_o   ,
  crc32_lst_o   ,
  //
  done_o        ,
  val_o         ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD  = 'd8 ; /*`LOG2(256)*/
  localparam LEN_DAT_WD  = 'd7 ; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD  = 'd7 ; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam DATA_WD     = 'd32;

  localparam NUM_WD      = 'd2 ;

  // fsm
  localparam FSM_WD      =  'd4;
  localparam IDLE        = 4'd0;
  localparam CMF_FLG     = 4'd1; // CMF, FLG
  localparam BLK_0       = 4'd2; // BFINAL, BTYPE
  localparam BLK_1       = 4'd3; // compressed data block
  localparam BLK_2       = 4'd4; // end of block
  localparam BLK_3       = 4'd5; // flush 0 to align with byte boundary
  localparam ADLER32     = 4'd6; // adler32
  localparam FLUSH       = 4'd7; // flush 0 to output remain
  localparam ZLIB_LEN    = 4'd8; // byte length of zlib data, assume no more than (1 << 32 - 1)

  // huffman fixed
  localparam HUF_CODE_WD = 'd19;
  localparam HUFC_W_D_WD = 'd5 ;

  // delay count for waiting crc32 process
  localparam DLY_CNT     = 'd4 ;
  localparam DLY_CNT_WD  = 'd2 ; /*`LOG2(DLY_CNT)*/

  // byte length of zlib data
  localparam ZLIB_LEN_WD = 'd32;

  // bitstream output
  localparam NUMB_WD     = 'd5 ;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk                ;
  input                      rstn               ;
  //
  input                      start_i            ;
  input                      val_i              ;
  input                      flg_lit_i          ;
  input  [LIT_DAT_WD  -1 :0] lit_dat_i          ;
  input  [LEN_DAT_WD  -1 :0] len_dat_i          ;
  input  [DIS_DAT_WD  -1 :0] dis_dat_i          ;
  input                      lst_i              ;
  //
  input                      adler32_done_i     ;
  input  [DATA_WD     -1 :0] adler32_dat_i      ;
  //
  output                     crc32_val_o        ;
  output [NUM_WD      -1 :0] crc32_num_o        ;
  output                     crc32_lst_o        ;
  //
  output                     done_o             ;
  output                     val_o              ;
  output [DATA_WD     -1 :0] dat_o              ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg    [FSM_WD      -1 :0] cur_state_r        ;
  reg    [FSM_WD      -1 :0] nxt_state_w        ;

  // huffman fixed
  wire   [HUF_CODE_WD -1 :0] huf_code_w         ;
  wire   [HUFC_W_D_WD -1 :0] huf_code_w_d_w     ;

  // delay count for waiting crc32 process
  reg    [DLY_CNT_WD  -1 :0] dly_cnt_r          ;

  // adler32 buffer
  reg    [DATA_WD     -1 :0] adler32_dat_buf_r  ;

  // byte length of zlib data
  wire   [ZLIB_LEN_WD -1 :0] zlib_len_nxt_w     ;
  reg    [ZLIB_LEN_WD -1 :0] zlib_len_r         ;

  // flush 0 numb accumulator
  wire   [NUMB_WD     -1 :0] bs_flush_numb_nxt_w;
  reg    [NUMB_WD     -1 :0] bs_flush_numb_r    ;

  // bitstream output signals
  wire                       bs_out_val_i_w     ;
  reg    [DATA_WD     -1 :0] bs_out_dat_i_w     ;
  reg    [NUMB_WD     -1 :0] bs_out_numb_i_w    ;
  wire                       bs_out_val_o_w     ;
  wire   [DATA_WD     -1 :0] bs_out_dat_o_w     ;

//***   MAIN BODY   ***********************************************************
//---   FSM   ---------------------------------------------
  // curr state
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cur_state_r <= IDLE;
    end
    else begin
      cur_state_r <= nxt_state_w;
    end
  end

  // next state
  always @(*) begin
    nxt_state_w = IDLE;
    case (cur_state_r)
      IDLE    : if (start_i)                    nxt_state_w = CMF_FLG ;
                else                            nxt_state_w = IDLE    ;
      CMF_FLG :                                 nxt_state_w = BLK_0   ;
      BLK_0   :                                 nxt_state_w = BLK_1   ;
      BLK_1   : if (lst_i)                      nxt_state_w = BLK_2   ;
                else                            nxt_state_w = BLK_1   ;
      BLK_2   : if (dly_cnt_r == DLY_CNT - 'd1) nxt_state_w = bs_flush_numb_nxt_w[2:0] != 'd0 ? BLK_3 : ADLER32;
                else                            nxt_state_w = BLK_2   ;
      BLK_3   : if (dly_cnt_r == DLY_CNT - 'd1) nxt_state_w = ADLER32 ;
                else                            nxt_state_w = BLK_3   ;
      ADLER32 : if (dly_cnt_r == DLY_CNT - 'd1) nxt_state_w = bs_flush_numb_nxt_w != 'd0 ? FLUSH : ZLIB_LEN;
                else                            nxt_state_w = ADLER32 ;
      FLUSH   : if (dly_cnt_r == DLY_CNT - 'd1) nxt_state_w = ZLIB_LEN;
                else                            nxt_state_w = FLUSH   ;
      ZLIB_LEN:                                 nxt_state_w = IDLE    ;
      default :                                 nxt_state_w = IDLE    ;
    endcase
  end

//---   HUFFMAN FIXED   -----------------------------------
  // inst huffman fixed
  huffman_fixed huffman_fixed(.flg_lit_i     (flg_lit_i     ),
                              .lit_dat_i     (lit_dat_i     ),
                              .len_dat_i     (len_dat_i     ),
                              .dis_dat_i     (dis_dat_i     ),
                              .huf_code_o    (huf_code_w    ),
                              .huf_code_w_d_o(huf_code_w_d_w) );

//---   BITSTREAM MISC  -----------------------------------
  // delay count for waiting crc32 process
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      dly_cnt_r <= 'd0;
    end
    else if (cur_state_r == BLK_2 || cur_state_r == BLK_3 || cur_state_r == ADLER32 || cur_state_r == FLUSH) begin
      if (dly_cnt_r == DLY_CNT - 'd1) begin
        dly_cnt_r <= 'd0;
      end
      else begin
        dly_cnt_r <= dly_cnt_r + 'd1;
      end
    end
  end

  // adler32 buffer
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      adler32_dat_buf_r <= 'd0;
    end
    else if (adler32_done_i) begin // !!! adler32 data should appear before ADLER32 state
      adler32_dat_buf_r <= adler32_dat_i;
    end
  end

  // byte length of zlib data
  assign zlib_len_nxt_w = zlib_len_r + ((bs_flush_numb_r[2:0] + bs_out_numb_i_w + 'd1) >> 'd3);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      zlib_len_r <= 'd0;
    end
    else if (cur_state_r == CMF_FLG || cur_state_r == BLK_0 || cur_state_r == BLK_1
           ||cur_state_r == BLK_2 || cur_state_r == BLK_3 || cur_state_r == ADLER32) begin
      if (bs_out_val_i_w) begin
        zlib_len_r <= zlib_len_nxt_w;
      end
    end
  end

  // crc32 output signals
  assign crc32_val_o = bs_out_val_o_w &&
                       (cur_state_r == CMF_FLG || cur_state_r == BLK_0 || cur_state_r == BLK_1 ||cur_state_r == BLK_2
                     || cur_state_r == BLK_3 || cur_state_r == ADLER32 || cur_state_r == FLUSH || cur_state_r == ZLIB_LEN); // !!! ADLER32 or FLUSH bitstream output will be valid in ZLIB_LEN state
  assign crc32_num_o = crc32_lst_o ? (zlib_len_r[1:0] - 'd1) : 'd3;
  assign crc32_lst_o = cur_state_r == ZLIB_LEN;

//---   BITSTREAM OUTPUT  ---------------------------------
  // flush 0 numb accumulator
  assign bs_flush_numb_nxt_w = bs_flush_numb_r + (bs_out_numb_i_w + 'd1); // mod 32 acc

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      bs_flush_numb_r <= 'd0;
    end
    else if (bs_out_val_i_w) begin
      bs_flush_numb_r <= bs_flush_numb_nxt_w;
    end
  end

  // bitstream output signals
  assign bs_out_val_i_w = (cur_state_r == CMF_FLG || cur_state_r == BLK_0)
                       || (cur_state_r == BLK_1 && val_i)  // !!! LZ77 data should only appear in this period
                       || ((cur_state_r == BLK_2 || cur_state_r == BLK_3 || cur_state_r == ADLER32 || cur_state_r == FLUSH) && (dly_cnt_r == DLY_CNT - 'd1))  // all need to wait crc32 process
                       || (cur_state_r == ZLIB_LEN);

  always @(*) begin
    bs_out_dat_i_w = 'd0;
    case (cur_state_r)
      CMF_FLG : bs_out_dat_i_w = 'b00011110_10000000; // !!! all bs_out_dat_i_w should reverse per byte
      BLK_0   : bs_out_dat_i_w = 'b1_10;
      BLK_1   : bs_out_dat_i_w = huf_code_w;
      BLK_2   : bs_out_dat_i_w = 'b0000000; // end of block huffman fixed code
      BLK_3   : bs_out_dat_i_w = 'b0;
      ADLER32 : bs_out_dat_i_w = {adler32_dat_buf_r[24], adler32_dat_buf_r[25], adler32_dat_buf_r[26], adler32_dat_buf_r[27],
                                  adler32_dat_buf_r[28], adler32_dat_buf_r[29], adler32_dat_buf_r[30], adler32_dat_buf_r[31],
                                  adler32_dat_buf_r[16], adler32_dat_buf_r[17], adler32_dat_buf_r[18], adler32_dat_buf_r[19],
                                  adler32_dat_buf_r[20], adler32_dat_buf_r[21], adler32_dat_buf_r[22], adler32_dat_buf_r[23],
                                  adler32_dat_buf_r[ 8], adler32_dat_buf_r[ 9], adler32_dat_buf_r[10], adler32_dat_buf_r[11],
                                  adler32_dat_buf_r[12], adler32_dat_buf_r[13], adler32_dat_buf_r[14], adler32_dat_buf_r[15],
                                  adler32_dat_buf_r[ 0], adler32_dat_buf_r[ 1], adler32_dat_buf_r[ 2], adler32_dat_buf_r[ 3],
                                  adler32_dat_buf_r[ 4], adler32_dat_buf_r[ 5], adler32_dat_buf_r[ 6], adler32_dat_buf_r[ 7]};
      FLUSH   : bs_out_dat_i_w = 'b0;
      ZLIB_LEN: bs_out_dat_i_w = {zlib_len_r[24], zlib_len_r[25], zlib_len_r[26], zlib_len_r[27],
                                  zlib_len_r[28], zlib_len_r[29], zlib_len_r[30], zlib_len_r[31],
                                  zlib_len_r[16], zlib_len_r[17], zlib_len_r[18], zlib_len_r[19],
                                  zlib_len_r[20], zlib_len_r[21], zlib_len_r[22], zlib_len_r[23],
                                  zlib_len_r[ 8], zlib_len_r[ 9], zlib_len_r[10], zlib_len_r[11],
                                  zlib_len_r[12], zlib_len_r[13], zlib_len_r[14], zlib_len_r[15],
                                  zlib_len_r[ 0], zlib_len_r[ 1], zlib_len_r[ 2], zlib_len_r[ 3],
                                  zlib_len_r[ 4], zlib_len_r[ 5], zlib_len_r[ 6], zlib_len_r[ 7]};
      default : bs_out_dat_i_w = 'b0;
    endcase
  end

  always @(*) begin
    bs_out_numb_i_w = 'd0;
    case (cur_state_r)
      CMF_FLG : bs_out_numb_i_w = 'd16 - 'd1;
      BLK_0   : bs_out_numb_i_w = 'd3 - 'd1;
      BLK_1   : bs_out_numb_i_w = huf_code_w_d_w - 'd1;
      BLK_2   : bs_out_numb_i_w = 'd7 - 'd1;
      BLK_3   : bs_out_numb_i_w = ('d8 - bs_flush_numb_r[2:0] -'d1);
      ADLER32 : bs_out_numb_i_w = 'd32 - 'd1;
      FLUSH   : bs_out_numb_i_w = ('d32 - bs_flush_numb_r - 'd1);
      ZLIB_LEN: bs_out_numb_i_w = 'd32 - 'd1;
      default : bs_out_numb_i_w = 'd0;
    endcase
  end

  // inst bitstream output
  bs_output bs_output(.clk   (clk            ),
                      .rstn  (rstn           ),
                      .val_i (bs_out_val_i_w ),
                      .dat_i (bs_out_dat_i_w ),
                      .numb_i(bs_out_numb_i_w),
                      .val_o (bs_out_val_o_w ),
                      .dat_o (bs_out_dat_o_w ) );

//---   OUTPUT   ------------------------------------------
  // dat_o
  assign dat_o = bs_out_dat_o_w;

  // val_o
  assign val_o = bs_out_val_o_w;

  // done_o
  assign done_o = (cur_state_r == IDLE && bs_out_val_o_w); // last bs_out_val_o_w


endmodule