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
  lst_i  ,
  //
  done_o ,
  val_o  ,
  dat_o
  );

//***   PARAMETER   ***********************************************************
  localparam DATA_WD      = 'd32;
  localparam SIZE_PIC_WD  = 'd32;

  // fsm
  localparam FSM_WD       =  'd2;
  localparam IDLE         = 2'd0;
  localparam IDAT         = 2'd1;
  localparam IHDR         = 2'd2;
  localparam IEND         = 2'd3;

  // steps counter for IHDR and IEND chunk
  localparam CNT_STP_MAX  = 'd6;
  localparam CNT_STP_IHDR = 'd6; // init, "IHDR", length, width, height, {bit depth, color type, compression method, filter method}, {interlace method, 0, 0, 0}
  localparam CNT_STP_IEND = 'd2; // init, "IEND", length
  localparam CNT_STP_WD   = /*`LOG2(CNT_MAX)*/'d3;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                      clk               ;
  input                      rstn              ;
  //
  input  [SIZE_PIC_WD -1 :0] w_i               ;
  input  [SIZE_PIC_WD -1 :0] h_i               ;
  //
  input                      start_i           ;
  input                      val_i             ;
  input  [DATA_WD     -1 :0] dat_i             ;
  input                      lst_i             ;
  //
  output                     done_o            ;
  output                     val_o             ;
  output [DATA_WD     -1 :0] dat_o             ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg         [FSM_WD     -1 :0] cur_state_r   ;
  reg         [FSM_WD     -1 :0] nxt_state_w   ;

  // steps counter for IHDR and IEND chunk
  reg         [CNT_STP_WD -1 :0] cnt_stp_r     ;

  // chunk crc32 core signals
  wire                           chunk_done_o_w;
  wire                           chunk_val_o_w ;

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
  // steps counter for IHDR and IEND chunk
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cnt_stp_r <= 'd0;
    end
    else begin
      case (cur_state_r)
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
  assign chunk_done_o_w = 'd0; // !!! temp
  assign chunk_val_o_w  = 'd0; // !!! temp


endmodule