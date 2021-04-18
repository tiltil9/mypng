//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module crc32(
  clk    ,
  rstn   ,
  //
  w_i    ,
  h_i    ,
  //
  start_i,
  val_i  ,
  dat_i  ,
  num_i  ,
  lst_i  ,
  //
  done_o ,
  val_o  ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD      = 'd32;
  localparam NUM_WD       = 'd2 ;
  localparam SIZE_PIC_WD  = 'd32;

  // fsm
  localparam FSM_WD       =  'd2;
  localparam IDLE         = 2'd0;
  localparam IDAT         = 2'd1;
  localparam IHDR         = 2'd2;
  localparam IEND         = 2'd3;

  // steps counter for chunk
  localparam CNT_STP_IDAT = 'd2; // init, "IDAT", xxxx...
  localparam CNT_STP_IHDR = 'd5; // init, "IHDR", width, height, {bit depth, color type, compression method, filter method}, {interlace method, 0, 0, 0}
  localparam CNT_STP_IEND = 'd1; // init, "IEND"
  localparam CNT_STP_MAX  = 'd5;
  localparam CNT_STP_WD   = 'd3; /*`LOG2(CNT_STP_MAX)*/

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk              ;
  input                      rstn             ;
  //
  input  [SIZE_PIC_WD -1 :0] w_i              ;
  input  [SIZE_PIC_WD -1 :0] h_i              ;
  //
  input                      start_i          ;
  input                      val_i            ;
  input  [DATA_WD     -1 :0] dat_i            ;
  input  [NUM_WD      -1 :0] num_i            ;
  input                      lst_i            ;
  //
  output                     done_o           ;
  output                     val_o            ;
  output [DATA_WD     -1 :0] dat_o            ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg    [FSM_WD     -1 :0] cur_state_r      ;
  reg    [FSM_WD     -1 :0] nxt_state_w      ;

  // steps counter for chunk
  reg    [CNT_STP_WD -1 :0] cnt_stp_r        ;

  // generate val_i for chunk
  reg                       chunk_val_i_gen_r;

  // chunk crc32 core signals
  wire                      chunk_start_i_w  ;
  wire                      chunk_val_i_w    ;
  reg    [DATA_WD    -1 :0] chunk_dat_i_w    ;
  reg    [NUM_WD     -1 :0] chunk_num_i_w    ;
  wire                      chunk_lst_i_w    ;
  wire                      chunk_done_o_w   ;
  wire                      chunk_val_o_w    ;
  wire   [DATA_WD    -1 :0] chunk_dat_o_w    ;

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
      IDLE   : if (start_i)        nxt_state_w = IDAT;
               else                nxt_state_w = IDLE;
      IDAT   : if (chunk_done_o_w) nxt_state_w = IHDR;
               else                nxt_state_w = IDAT;
      IHDR   : if (chunk_done_o_w) nxt_state_w = IEND;
               else                nxt_state_w = IHDR;
      IEND   : if (chunk_done_o_w) nxt_state_w = IDLE;
               else                nxt_state_w = IEND;
      default: nxt_state_w = IDLE;
    endcase
  end

//---   COUNT   -------------------------------------------
  // steps counter for chunk
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cnt_stp_r <= 'd0;
    end
    else begin
      case (cur_state_r)
        IDAT   : if (cnt_stp_r == CNT_STP_IDAT && chunk_done_o_w) begin
                   cnt_stp_r <= 'd0;
                 end
                 else if (cnt_stp_r == 'd0 || (cnt_stp_r != 'd0 && chunk_val_o_w)) begin
                   cnt_stp_r <= cnt_stp_r + 'd1;
                 end
        IHDR   : if (cnt_stp_r == CNT_STP_IHDR && chunk_done_o_w) begin
                   cnt_stp_r <= 'd0;
                 end
                 else if (cnt_stp_r == 'd0 || (cnt_stp_r != 'd0 && chunk_val_o_w)) begin
                   cnt_stp_r <= cnt_stp_r + 'd1;
                 end
        IEND   : if (cnt_stp_r == CNT_STP_IEND && chunk_done_o_w) begin
                   cnt_stp_r <= 'd0;
                 end
                 else if (cnt_stp_r == 'd0 || (cnt_stp_r != 'd0 && chunk_val_o_w)) begin
                   cnt_stp_r <= cnt_stp_r + 'd1;
                 end
        default: ;
      endcase
    end
  end

//---   PROC   --------------------------------------------
  // generate val_i for chunk
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      chunk_val_i_gen_r <= 'd0;
    end
    else begin
      case (cur_state_r)
        IDAT   : if (cnt_stp_r == 'd0) begin
                   chunk_val_i_gen_r <= 'd1;
                 end
                 else begin
                   chunk_val_i_gen_r <= 'd0;
                 end
        IHDR   : if (cnt_stp_r == 'd0 || (cnt_stp_r != 'd0 && cnt_stp_r != CNT_STP_IHDR && chunk_val_o_w)) begin
                   chunk_val_i_gen_r <= 'd1;
                 end
                 else begin
                   chunk_val_i_gen_r <= 'd0;
                 end
        IEND   : if (cnt_stp_r == 'd0 || (cnt_stp_r != 'd0 && cnt_stp_r != CNT_STP_IEND && chunk_val_o_w)) begin
                   chunk_val_i_gen_r <= 'd1;
                 end
                 else begin
                   chunk_val_i_gen_r <= 'd0;
                 end
        default: ;
      endcase
    end
  end

  // chunk crc32 core signals
  assign chunk_start_i_w = (cur_state_r == IDAT && cnt_stp_r == 'd0) || (cur_state_r == IHDR && cnt_stp_r == 'd0) || (cur_state_r == IEND && cnt_stp_r == 'd0);
  assign chunk_val_i_w   = (cur_state_r == IDAT && cnt_stp_r == 'd1          && chunk_val_i_gen_r)
                        || (cur_state_r == IDAT && cnt_stp_r == CNT_STP_IDAT && val_i            )  // !!! IDAT data should only appear in this period
                        || (cur_state_r == IHDR                              && chunk_val_i_gen_r)
                        || (cur_state_r == IEND                              && chunk_val_i_gen_r); // !!! chunk_val_i_w should valid only a cycle once time
  assign chunk_lst_i_w   = (cur_state_r == IDAT && cnt_stp_r == CNT_STP_IDAT && lst_i) || (cur_state_r == IHDR && cnt_stp_r == CNT_STP_IHDR) || (cur_state_r == IEND && cnt_stp_r == CNT_STP_IEND);

  always @(*) begin
    chunk_dat_i_w = 'd0;
    case (cur_state_r)
      IDAT   : if (cnt_stp_r == 'd1)      chunk_dat_i_w = 32'h49_44_41_54; // "IDAT"
               else if (cnt_stp_r == 'd2) chunk_dat_i_w = dat_i;
               else                       chunk_dat_i_w = 'd0;
      IHDR   : if (cnt_stp_r == 'd1)      chunk_dat_i_w = 32'h49_48_44_52; // "IHDR"
               else if (cnt_stp_r == 'd2) chunk_dat_i_w = w_i;             // width
               else if (cnt_stp_r == 'd3) chunk_dat_i_w = h_i;             // height
               else if (cnt_stp_r == 'd4) chunk_dat_i_w = 32'h08_06_00_00; // {bit depth, color type, compression method, filter method}
               else if (cnt_stp_r == 'd5) chunk_dat_i_w = 32'h00_00_00_00; // {interlace method, 0, 0, 0}
               else                       chunk_dat_i_w = 'd0;
      IEND   : if (cnt_stp_r == 'd1)      chunk_dat_i_w = 32'h49_45_4E_44; // "IEND"
               else                       chunk_dat_i_w = 'd0;
      default:                            chunk_dat_i_w = 'd0;
    endcase
  end

  always @(*) begin
    chunk_num_i_w = 'd0;
    case (cur_state_r)
      IDAT   : if (cnt_stp_r == 'd1)      chunk_num_i_w = 'd3;
               else if (cnt_stp_r == 'd2) chunk_num_i_w = num_i;
               else                       chunk_num_i_w = 'd0;
      IHDR   : if (cnt_stp_r == 'd5)      chunk_num_i_w = 'd0; // only 1 most significant byte is valid
               else if (cnt_stp_r == 'd1
                     || cnt_stp_r == 'd2
                     || cnt_stp_r == 'd3
                     || cnt_stp_r == 'd4) chunk_num_i_w = 'd3;
               else                       chunk_num_i_w = 'd0;
      IEND   : if (cnt_stp_r == 'd1)      chunk_num_i_w = 'd3;
               else                       chunk_num_i_w = 'd0;
      default:                            chunk_num_i_w = 'd0;
    endcase
  end

  // inst chunk crc32 core
  crc32_core chunk_crc32_core(.clk    (clk            ),
                              .rstn   (rstn           ),
                              .start_i(chunk_start_i_w),
                              .val_i  (chunk_val_i_w  ),
                              .dat_i  (chunk_dat_i_w  ),
                              .num_i  (chunk_num_i_w  ),
                              .lst_i  (chunk_lst_i_w  ),
                              .done_o (chunk_done_o_w ),
                              .val_o  (chunk_val_o_w  ),
                              .dat_o  (chunk_dat_o_w  ) );

//---   OUTPUT   ------------------------------------------
  // dat_o
  assign dat_o = chunk_dat_o_w;

  // val_o
  assign val_o = chunk_done_o_w;

  // done_o
  assign done_o = (cur_state_r == IEND && chunk_done_o_w);


endmodule