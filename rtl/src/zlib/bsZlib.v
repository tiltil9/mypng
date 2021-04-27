//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module bsZlib(
  clk      ,
  rstn     ,
  //
  start_i  ,
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

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD  = 'd8 ; /*`LOG2(256)*/
  localparam LEN_DAT_WD  = 'd7 ; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD  = 'd7 ; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam DATA_WD     = 'd32;

  // fsm
  localparam FSM_WD      =  'd3;
  localparam IDLE        = 3'd0;
  localparam CMF_FLG     = 3'd1; // CMF, FLG
  localparam BLK_0       = 3'd2; // BFINAL, BTYPE
  localparam BLK_1       = 3'd3; // compressed data block
  localparam BLK_2       = 3'd4; // end of block
  localparam BLK_3       = 3'd5; // flush 0 to align with byte boundary
  localparam ADLER32     = 3'd6; // TODO: may merge adler32 bs
  localparam FLUSH       = 3'd7; // flush 0 to output remain // TODO: may add num_o

  // huffman fixed
  localparam HUF_CODE_WD = 'd19;
  localparam HUFC_W_D_WD = 'd5 ;

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
      IDLE   : if (start_i)                         nxt_state_w = CMF_FLG;
               else                                 nxt_state_w = IDLE   ;
      CMF_FLG:                                      nxt_state_w = BLK_0  ;
      BLK_0  :                                      nxt_state_w = BLK_1  ;
      BLK_1  : if (lst_i)                           nxt_state_w = BLK_2  ;
               else                                 nxt_state_w = BLK_1  ;
      BLK_2  : if (bs_flush_numb_nxt_w[2:0] != 'd0) nxt_state_w = BLK_3  ;
               else                                 nxt_state_w = ADLER32;
      BLK_3  :                                      nxt_state_w = ADLER32;
      ADLER32: if (bs_flush_numb_nxt_w != 'd0)      nxt_state_w = FLUSH  ;
               else                                 nxt_state_w = IDLE   ;
      FLUSH  :                                      nxt_state_w = IDLE   ;
      default:                                      nxt_state_w = IDLE   ;
    endcase
  end

//---   HUFFMAN FIXED   -----------------------------------
  // inst huffman fixed
  huffmanFixed huffmanFixed(.flg_lit_i     (flg_lit_i     ),
                            .lit_dat_i     (lit_dat_i     ),
                            .len_dat_i     (len_dat_i     ),
                            .dis_dat_i     (dis_dat_i     ),
                            .huf_code_o    (huf_code_w    ),
                            .huf_code_w_d_o(huf_code_w_d_w) );

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
                       || (cur_state_r == BLK_2 || cur_state_r == BLK_3 || cur_state_r == ADLER32 || cur_state_r == FLUSH);

  always @(*) begin
    bs_out_dat_i_w = 'd0;
    case (cur_state_r)
      CMF_FLG: bs_out_dat_i_w = 'b00011110_10000000; // !!! should reverse per byte
      BLK_0  : bs_out_dat_i_w = 'b1_10;
      BLK_1  : bs_out_dat_i_w = huf_code_w;
      BLK_2  : bs_out_dat_i_w = 'b0000000; // end of block huffman fixed code
      BLK_3  : bs_out_dat_i_w = 'b0;
      ADLER32: bs_out_dat_i_w = 'h482c6a1e; //TODO: may merge adler32 bs
      FLUSH  : bs_out_dat_i_w = 'b0;
      default: bs_out_dat_i_w = 'b0;
    endcase
  end

  always @(*) begin
    bs_out_numb_i_w = 'd0;
    case (cur_state_r)
      CMF_FLG: bs_out_numb_i_w = 'd16 - 'd1;
      BLK_0  : bs_out_numb_i_w = 'd3 - 'd1;
      BLK_1  : bs_out_numb_i_w = huf_code_w_d_w - 'd1;
      BLK_2  : bs_out_numb_i_w = 'd7 - 'd1;
      BLK_3  : bs_out_numb_i_w = ('d8 - bs_flush_numb_r[2:0] -'d1);
      ADLER32: bs_out_numb_i_w = 'd32 - 'd1;
      FLUSH  : bs_out_numb_i_w = ('d32 - bs_flush_numb_r - 'd1);
      default: bs_out_numb_i_w = 'd0;
    endcase
  end

  // inst bitstream output
  bsOut bsOut(.clk   (clk            ),
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