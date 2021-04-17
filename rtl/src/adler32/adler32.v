//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module adler32(
  clk    ,
  rstn   ,
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
  localparam DATA_WD         = 'd32;
  localparam ADLER32_WD      = 'd32;
  localparam ADLER32_HALF_WD = 'd16;

  // din process
  localparam DIN_WD          = 'd8 ;

  // fsm
  localparam FSM_WD          =  'd3;
  localparam IDLE            = 3'd0;
  localparam ACTV            = 3'd1;
  localparam PROC_2          = 3'd2;
  localparam PROC_3          = 3'd3;
  localparam PROC_4          = 3'd4;
  localparam LAST_2          = 3'd5;
  localparam LAST_3          = 3'd6;
  localparam LAST_4          = 3'd7;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                                clk                 ;
  input                                rstn                ;
  //
  input                                start_i             ;
  input                                val_i               ;
  input      [DATA_WD           -1 :0] dat_i               ;
  input                                lst_i               ;
  //
  output reg                           done_o              ;
  output reg                           val_o               ;
  output     [DATA_WD           -1 :0] dat_o               ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg        [FSM_WD     -1 :0]        cur_state_r         ;
  reg        [FSM_WD     -1 :0]        nxt_state_w         ;

  // dat_i buffer
  reg        [DATA_WD    -1 :0]        dat_i_buf_r         ;

  // din
  reg        [DIN_WD            -1 :0] din_w               ;

  // adler32 s2 and s1
  reg        [ADLER32_HALF_WD   -1 :0] adler32_s2_cur_r    ;
  reg        [ADLER32_HALF_WD   -1 :0] adler32_s1_cur_r    ;

  // adler32 s2 and s1 calculation
  wire       [ADLER32_HALF_WD+2 -1 :0] adler32_s2_nxt_sum_w;
  wire       [ADLER32_HALF_WD+1 -1 :0] adler32_s1_nxt_sum_w;

  wire       [ADLER32_HALF_WD   -1 :0] adler32_s2_nxt_w    ;
  wire       [ADLER32_HALF_WD   -1 :0] adler32_s1_nxt_w    ;

  // adler32 checksum
  wire       [ADLER32_WD        -1 :0] adler32_cur_w       ;

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
      IDLE   : if (start_i)             nxt_state_w = ACTV  ;
               else                     nxt_state_w = IDLE  ;
      ACTV   : if (val_i && !lst_i)     nxt_state_w = PROC_2;
               else if (val_i && lst_i) nxt_state_w = LAST_2;
               else                     nxt_state_w = ACTV  ;
      PROC_2 :                          nxt_state_w = PROC_3;
      PROC_3 :                          nxt_state_w = PROC_4;
      PROC_4 :                          nxt_state_w = ACTV  ;
      LAST_2 :                          nxt_state_w = LAST_3;
      LAST_3 :                          nxt_state_w = LAST_4;
      LAST_4 :                          nxt_state_w = IDLE  ;
      default:                          nxt_state_w = IDLE  ;
    endcase
  end

//---   PREPARE   -----------------------------------------
  // dat_i buffer
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      dat_i_buf_r <= 'd0;
    end
    else if (cur_state_r == ACTV && val_i) begin
      dat_i_buf_r <= dat_i;
    end
  end

  // dat_i[31:24], [23:16], [15:8], [7:0] mapped to din_w[7:0]
  always @(*) begin
    din_w = 'd0;
    case (cur_state_r)
      ACTV           : din_w = dat_i[31:24]      ; // look ahead
      PROC_2, LAST_2 : din_w = dat_i_buf_r[23:16];
      PROC_3, LAST_3 : din_w = dat_i_buf_r[15: 8];
      PROC_4, LAST_4 : din_w = dat_i_buf_r[ 7: 0];
      default : din_w = 'd0;
    endcase
  end

//---   CALC   --------------------------------------------
  // adler32 s2 and s1
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      adler32_s2_cur_r <= 16'h0000;
      adler32_s1_cur_r <= 16'h0000;
    end
    else begin
      case (cur_state_r)
        IDLE   : if (start_i) begin
                   adler32_s2_cur_r <= 16'h0000;
                   adler32_s1_cur_r <= 16'h0001;
                 end
        ACTV   : if (val_i) begin
                   adler32_s2_cur_r <= adler32_s2_nxt_w;
                   adler32_s1_cur_r <= adler32_s1_nxt_w;
                 end
        PROC_2,
        LAST_2 : begin
                   adler32_s2_cur_r <= adler32_s2_nxt_w;
                   adler32_s1_cur_r <= adler32_s1_nxt_w;
                 end
        PROC_3,
        LAST_3 : begin
                   adler32_s2_cur_r <= adler32_s2_nxt_w;
                   adler32_s1_cur_r <= adler32_s1_nxt_w;
                 end
        PROC_4,
        LAST_4 : begin
                   adler32_s2_cur_r <= adler32_s2_nxt_w;
                   adler32_s1_cur_r <= adler32_s1_nxt_w;
                 end
        default: ;
      endcase
    end
  end

  // sum
  assign adler32_s2_nxt_sum_w = adler32_s2_cur_r + adler32_s1_nxt_sum_w;
  assign adler32_s1_nxt_sum_w = adler32_s1_cur_r + din_w;

  // mod 16'd65521 (implement utilizing range information and minus operation)
  assign adler32_s2_nxt_w = (adler32_s2_nxt_sum_w >= 'd131042) ? (adler32_s2_nxt_sum_w - 'd131042)
                          : (adler32_s2_nxt_sum_w >= 'd65521 ) ? (adler32_s2_nxt_sum_w - 'd65521 )
                          :  adler32_s2_nxt_sum_w;
  assign adler32_s1_nxt_w = (adler32_s1_nxt_sum_w >= 'd65521 ) ? (adler32_s1_nxt_sum_w - 'd65521 ) : adler32_s1_nxt_sum_w;

//---   OUTPUT   ------------------------------------------
  // adler32 checksum
  assign adler32_cur_w = {adler32_s2_cur_r, adler32_s1_cur_r};

  // dat_o
  assign dat_o = adler32_cur_w;

  // val_o
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      val_o <= 'd0;
    end
    else begin
      if (cur_state_r == PROC_4 || cur_state_r == LAST_4) begin
        val_o <= 'd1;
      end
      else begin
        val_o <= 'd0;
      end
    end
  end

  // done_o
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      done_o <= 'd0;
    end
    else begin
      if (cur_state_r == LAST_4) begin
        done_o <= 'd1;
      end
      else begin
        done_o <= 'd0;
      end
    end
  end


endmodule