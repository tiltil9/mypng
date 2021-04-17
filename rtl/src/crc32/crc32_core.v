//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module crc32_core(
  clk    ,
  rstn   ,
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
  localparam DATA_WD    = 'd32;
  localparam NUM_WD     = 'd2 ;
  localparam CRC32_WD   = 'd32;

  // din process
  localparam DIN_WD     = 'd8 ;

  // fsm
  localparam FSM_WD     =  'd3;
  localparam IDLE       = 3'd0;
  localparam ACTV       = 3'd1;
  localparam PROC_2     = 3'd2;
  localparam PROC_3     = 3'd3;
  localparam PROC_4     = 3'd4;
  localparam LAST_2     = 3'd5;
  localparam LAST_3     = 3'd6;
  localparam LAST_4     = 3'd7;

//***   INPUT / OUTPUT   ******************************************************
  //
  input                         clk            ;
  input                         rstn           ;
  //
  input                         start_i        ;
  input                         val_i          ;
  input      [DATA_WD    -1 :0] dat_i          ;
  input      [NUM_WD     -1 :0] num_i          ; // means 1/2/3/4 most significant bytes are valid
  input                         lst_i          ;
  //
  output reg                    done_o         ;
  output reg                    val_o          ;
  output     [DATA_WD    -1 :0] dat_o          ;

//***   WIRE / REG   **********************************************************
  // fsm
  reg         [FSM_WD     -1 :0] cur_state_r    ;
  reg         [FSM_WD     -1 :0] nxt_state_w    ;

  // dat_i and num_i buffer
  reg         [DATA_WD    -1 :0] dat_i_buf_r    ;
  reg         [NUM_WD     -1 :0] num_i_buf_r    ;

  // crc32 and din in normal order
  reg         [DIN_WD     -1 :0] din_nrm_w      ;
  reg         [CRC32_WD   -1 :0] crc32_nrm_cur_r;
  reg         [CRC32_WD   -1 :0] crc32_nrm_nxt_w;

  // crc32 in reversed order
  wire        [CRC32_WD   -1 :0] crc32_rvs_cur_w;

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
  // dat_i and num_i buffer
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      dat_i_buf_r <= 'd0;
      num_i_buf_r <= 'd0;
    end
    else if (cur_state_r == ACTV && val_i) begin
      dat_i_buf_r <= dat_i;
      num_i_buf_r <= num_i;
    end
  end

  // reversed order dat_i/buf_r[31:24], [23:16], [15:8], [7:0] mapped to normal order din_nrm_w[7:0]
  always @(*) begin
    din_nrm_w = 'd0;
    case (cur_state_r)
      ACTV           : din_nrm_w = {dat_i[24]      , dat_i[25]      , dat_i[26]      , dat_i[27]      , dat_i[28]      , dat_i[29]      , dat_i[30]      , dat_i[31]      }; // look ahead
      PROC_2, LAST_2 : din_nrm_w = {dat_i_buf_r[16], dat_i_buf_r[17], dat_i_buf_r[18], dat_i_buf_r[19], dat_i_buf_r[20], dat_i_buf_r[21], dat_i_buf_r[22], dat_i_buf_r[23]};
      PROC_3, LAST_3 : din_nrm_w = {dat_i_buf_r[ 8], dat_i_buf_r[ 9], dat_i_buf_r[10], dat_i_buf_r[11], dat_i_buf_r[12], dat_i_buf_r[13], dat_i_buf_r[14], dat_i_buf_r[15]};
      PROC_4, LAST_4 : din_nrm_w = {dat_i_buf_r[ 0], dat_i_buf_r[ 1], dat_i_buf_r[ 2], dat_i_buf_r[ 3], dat_i_buf_r[ 4], dat_i_buf_r[ 5], dat_i_buf_r[ 6], dat_i_buf_r[ 7]};
      default: din_nrm_w = 'd0;
    endcase
  end

//---   CALC   --------------------------------------------
  // normal order crc32_nrm_cur_r[31:0]
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      crc32_nrm_cur_r <= 32'h0;
    end
    else begin
      case (cur_state_r)
        IDLE           : if (start_i)               crc32_nrm_cur_r <= 32'hffff_ffff  ;
        ACTV           : if (val_i && num_i >= 'd0) crc32_nrm_cur_r <= crc32_nrm_nxt_w; // look ahead
        PROC_2, LAST_2 : if (num_i_buf_r >= 'd1)    crc32_nrm_cur_r <= crc32_nrm_nxt_w;
        PROC_3, LAST_3 : if (num_i_buf_r >= 'd2)    crc32_nrm_cur_r <= crc32_nrm_nxt_w;
        PROC_4, LAST_4 : if (num_i_buf_r >= 'd3)    crc32_nrm_cur_r <= crc32_nrm_nxt_w;
        default: ;
      endcase
    end
  end

  // crc32_nrm_nxt_w[31:0] calculated according to crc32_nrm_cur_r[31:0] and din_nrm_w[7:0]
  // poly is 0x04C11DB7, these codes are modified according to easics crc generation tool
  always @(*) begin
    crc32_nrm_nxt_w[ 0] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[ 1] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 2] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 3] = crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 4] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[ 5] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 6] = crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 7] = crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[ 8] = crc32_nrm_cur_r[ 0] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[ 9] = crc32_nrm_cur_r[ 1] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[10] = crc32_nrm_cur_r[ 2] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[0] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[11] = crc32_nrm_cur_r[ 3] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[3] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[12] = crc32_nrm_cur_r[ 4] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[13] = crc32_nrm_cur_r[ 5] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[5] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[14] = crc32_nrm_cur_r[ 6] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[2] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[15] = crc32_nrm_cur_r[ 7] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[16] = crc32_nrm_cur_r[ 8] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[0] ^ din_nrm_w[4] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[17] = crc32_nrm_cur_r[ 9] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[1] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[18] = crc32_nrm_cur_r[10] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[2] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[19] = crc32_nrm_cur_r[11] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[20] = crc32_nrm_cur_r[12] ^ crc32_nrm_cur_r[28] ^ din_nrm_w[4];
    crc32_nrm_nxt_w[21] = crc32_nrm_cur_r[13] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[5];
    crc32_nrm_nxt_w[22] = crc32_nrm_cur_r[14] ^ crc32_nrm_cur_r[24] ^ din_nrm_w[0];
    crc32_nrm_nxt_w[23] = crc32_nrm_cur_r[15] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[1] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[24] = crc32_nrm_cur_r[16] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[2] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[25] = crc32_nrm_cur_r[17] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[27] ^ din_nrm_w[2] ^ din_nrm_w[3];
    crc32_nrm_nxt_w[26] = crc32_nrm_cur_r[18] ^ crc32_nrm_cur_r[24] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[0] ^ din_nrm_w[3] ^ din_nrm_w[4] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[27] = crc32_nrm_cur_r[19] ^ crc32_nrm_cur_r[25] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[1] ^ din_nrm_w[4] ^ din_nrm_w[5] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[28] = crc32_nrm_cur_r[20] ^ crc32_nrm_cur_r[26] ^ crc32_nrm_cur_r[29] ^ crc32_nrm_cur_r[30] ^ din_nrm_w[2] ^ din_nrm_w[5] ^ din_nrm_w[6];
    crc32_nrm_nxt_w[29] = crc32_nrm_cur_r[21] ^ crc32_nrm_cur_r[27] ^ crc32_nrm_cur_r[30] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[3] ^ din_nrm_w[6] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[30] = crc32_nrm_cur_r[22] ^ crc32_nrm_cur_r[28] ^ crc32_nrm_cur_r[31] ^ din_nrm_w[4] ^ din_nrm_w[7];
    crc32_nrm_nxt_w[31] = crc32_nrm_cur_r[23] ^ crc32_nrm_cur_r[29] ^ din_nrm_w[5];
  end

//---   OUTPUT   ------------------------------------------
  // normal order crc32_nrm_cur_r[31:0] mapped to reversed order crc32_rvs_cur_w[31:0]
  assign crc32_rvs_cur_w = {crc32_nrm_cur_r[ 0], crc32_nrm_cur_r[ 1], crc32_nrm_cur_r[ 2], crc32_nrm_cur_r[ 3],
                            crc32_nrm_cur_r[ 4], crc32_nrm_cur_r[ 5], crc32_nrm_cur_r[ 6], crc32_nrm_cur_r[ 7],
                            crc32_nrm_cur_r[ 8], crc32_nrm_cur_r[ 9], crc32_nrm_cur_r[10], crc32_nrm_cur_r[11],
                            crc32_nrm_cur_r[12], crc32_nrm_cur_r[13], crc32_nrm_cur_r[14], crc32_nrm_cur_r[15],
                            crc32_nrm_cur_r[16], crc32_nrm_cur_r[17], crc32_nrm_cur_r[18], crc32_nrm_cur_r[19],
                            crc32_nrm_cur_r[20], crc32_nrm_cur_r[21], crc32_nrm_cur_r[22], crc32_nrm_cur_r[23],
                            crc32_nrm_cur_r[24], crc32_nrm_cur_r[25], crc32_nrm_cur_r[26], crc32_nrm_cur_r[27],
                            crc32_nrm_cur_r[28], crc32_nrm_cur_r[29], crc32_nrm_cur_r[30], crc32_nrm_cur_r[31] };

  // reversed order crc32_rvs_cur_w[31:0] xor with 0xFFFFFFFF
  assign dat_o = crc32_rvs_cur_w ^ 32'hffff_ffff;

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