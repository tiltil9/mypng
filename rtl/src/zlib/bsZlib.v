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
  localparam CMF         = 3'd1;
  localparam FLG         = 3'd2;
  localparam BLK_0       = 3'd3; // BFINAL, BTYPE
  localparam BLK_1       = 3'd4; // compressed data block
  localparam BLK_2       = 3'd5; // end of block
  localparam BLK_3       = 3'd6; // flush 0
  localparam ADLER32     = 3'd7; // TODO: may merge adler32 bs

  // huffman fixed
  localparam HUF_CODE_WD = 'd19;
  localparam HUFC_W_D_WD = 'd5 ;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk           ;
  input                      rstn          ;
  //
  input                      start_i       ;
  input                      val_i         ;
  input                      flg_lit_i     ;
  input  [LIT_DAT_WD  -1 :0] lit_dat_i     ;
  input  [LEN_DAT_WD  -1 :0] len_dat_i     ;
  input  [DIS_DAT_WD  -1 :0] dis_dat_i     ;
  input                      lst_i         ;
  //
  output                     done_o        ;
  output                     val_o         ;
  output [DATA_WD     -1 :0] dat_o         ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg    [FSM_WD      -1 :0] cur_state_r   ;
  reg    [FSM_WD      -1 :0] nxt_state_w   ;

  // huffman fixed
  wire   [HUF_CODE_WD -1 :0] huf_code_w    ;
  wire   [HUFC_W_D_WD -1 :0] huf_code_w_d_w;

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
      IDLE   : if (start_i) nxt_state_w = CMF    ;
               else         nxt_state_w = IDLE   ;
      CMF    :              nxt_state_w = FLG    ;
      FLG    :              nxt_state_w = BLK_0  ;
      BLK_0  :              nxt_state_w = BLK_1  ;
      BLK_1  : if (lst_i)   nxt_state_w = BLK_2  ;
               else         nxt_state_w = BLK_1  ;
      BLK_2  :              nxt_state_w = BLK_3  ;
      BLK_3  :              nxt_state_w = ADLER32;
      ADLER32:              nxt_state_w = IDLE   ;
      default:              nxt_state_w = IDLE   ;
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


endmodule