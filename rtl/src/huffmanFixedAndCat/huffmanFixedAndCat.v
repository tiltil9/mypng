//------------------------------------------------------------------------------
  //
  //  Filename      : 
  //  Description   : 
  //  Author        : 
  //  Email         :
  //  Created       : xxxx-xx-xx
  //
//------------------------------------------------------------------------------

module huffmanFixedAndCat(
  clk      ,
  rstn     ,
  //
  val_i    ,
  flg_lit_i,
  lit_dat_i,
  len_dat_i,
  dis_dat_i 
  //
  );

//***   PARAMETER   ***********************************************************
  // !!! assume `NICE_MATCH and `WINDOW_SIZE are both no more than 64 yet
  localparam LIT_DAT_WD  = 'd8; /*`LOG2(256)*/
  localparam LEN_DAT_WD  = 'd7; /*`LOG2(`NICE_MATCH)!!!+1*/
  localparam DIS_DAT_WD  = 'd7; /*`LOG2(`WINDOW_SIZE)!!!+1*/

  localparam LIT_CODE_WD = 'd9;
  localparam LEN_CODE_WD = 'd10; // huffman 7 bits + extra 3 bits
  localparam DIS_CODE_WD = 'd9;  // huffman 5 bits + extra 4 bits
  localparam CODE_WD_WD  = 'd4;  /*`LOG2(CODE_WD_MAX)*/

//***   INPUT / OUTPUT   ******************************************************
  //
  input                     clk          ;
  input                     rstn         ;
  //
  input                     val_i        ;
  input                     flg_lit_i    ;
  input [LIT_DAT_WD  -1 :0] lit_dat_i    ;
  input [LEN_DAT_WD  -1 :0] len_dat_i    ;
  input [DIS_DAT_WD  -1 :0] dis_dat_i    ;

//***   WIRE / REG   **********************************************************
  // code
  reg   [LIT_CODE_WD -1 :0] lit_code_w   ;
  reg   [LEN_CODE_WD -1 :0] len_code_w   ;
  reg   [DIS_CODE_WD -1 :0] dis_code_w   ;
  // code width
  reg   [CODE_WD_WD  -1 :0] lit_code_wd_w;
  reg   [CODE_WD_WD  -1 :0] len_code_wd_w;
  reg   [CODE_WD_WD  -1 :0] dis_code_wd_w;

//***   MAIN BODY   ***********************************************************
//---   CODE   --------------------------------------------
  // TODO : may simply the table
  // literal code
  always @(*) begin
    lit_code_w = 'd0;
    case(lit_dat_i)
      'd0  : lit_code_w = 'b00110000 ;
      'd1  : lit_code_w = 'b00110001 ;
      'd2  : lit_code_w = 'b00110010 ;
      'd3  : lit_code_w = 'b00110011 ;
      'd4  : lit_code_w = 'b00110100 ;
      'd5  : lit_code_w = 'b00110101 ;
      'd6  : lit_code_w = 'b00110110 ;
      'd7  : lit_code_w = 'b00110111 ;
      'd8  : lit_code_w = 'b00111000 ;
      'd9  : lit_code_w = 'b00111001 ;
      'd10 : lit_code_w = 'b00111010 ;
      'd11 : lit_code_w = 'b00111011 ;
      'd12 : lit_code_w = 'b00111100 ;
      'd13 : lit_code_w = 'b00111101 ;
      'd14 : lit_code_w = 'b00111110 ;
      'd15 : lit_code_w = 'b00111111 ;
      'd16 : lit_code_w = 'b01000000 ;
      'd17 : lit_code_w = 'b01000001 ;
      'd18 : lit_code_w = 'b01000010 ;
      'd19 : lit_code_w = 'b01000011 ;
      'd20 : lit_code_w = 'b01000100 ;
      'd21 : lit_code_w = 'b01000101 ;
      'd22 : lit_code_w = 'b01000110 ;
      'd23 : lit_code_w = 'b01000111 ;
      'd24 : lit_code_w = 'b01001000 ;
      'd25 : lit_code_w = 'b01001001 ;
      'd26 : lit_code_w = 'b01001010 ;
      'd27 : lit_code_w = 'b01001011 ;
      'd28 : lit_code_w = 'b01001100 ;
      'd29 : lit_code_w = 'b01001101 ;
      'd30 : lit_code_w = 'b01001110 ;
      'd31 : lit_code_w = 'b01001111 ;
      'd32 : lit_code_w = 'b01010000 ;
      'd33 : lit_code_w = 'b01010001 ;
      'd34 : lit_code_w = 'b01010010 ;
      'd35 : lit_code_w = 'b01010011 ;
      'd36 : lit_code_w = 'b01010100 ;
      'd37 : lit_code_w = 'b01010101 ;
      'd38 : lit_code_w = 'b01010110 ;
      'd39 : lit_code_w = 'b01010111 ;
      'd40 : lit_code_w = 'b01011000 ;
      'd41 : lit_code_w = 'b01011001 ;
      'd42 : lit_code_w = 'b01011010 ;
      'd43 : lit_code_w = 'b01011011 ;
      'd44 : lit_code_w = 'b01011100 ;
      'd45 : lit_code_w = 'b01011101 ;
      'd46 : lit_code_w = 'b01011110 ;
      'd47 : lit_code_w = 'b01011111 ;
      'd48 : lit_code_w = 'b01100000 ;
      'd49 : lit_code_w = 'b01100001 ;
      'd50 : lit_code_w = 'b01100010 ;
      'd51 : lit_code_w = 'b01100011 ;
      'd52 : lit_code_w = 'b01100100 ;
      'd53 : lit_code_w = 'b01100101 ;
      'd54 : lit_code_w = 'b01100110 ;
      'd55 : lit_code_w = 'b01100111 ;
      'd56 : lit_code_w = 'b01101000 ;
      'd57 : lit_code_w = 'b01101001 ;
      'd58 : lit_code_w = 'b01101010 ;
      'd59 : lit_code_w = 'b01101011 ;
      'd60 : lit_code_w = 'b01101100 ;
      'd61 : lit_code_w = 'b01101101 ;
      'd62 : lit_code_w = 'b01101110 ;
      'd63 : lit_code_w = 'b01101111 ;
      'd64 : lit_code_w = 'b01110000 ;
      'd65 : lit_code_w = 'b01110001 ;
      'd66 : lit_code_w = 'b01110010 ;
      'd67 : lit_code_w = 'b01110011 ;
      'd68 : lit_code_w = 'b01110100 ;
      'd69 : lit_code_w = 'b01110101 ;
      'd70 : lit_code_w = 'b01110110 ;
      'd71 : lit_code_w = 'b01110111 ;
      'd72 : lit_code_w = 'b01111000 ;
      'd73 : lit_code_w = 'b01111001 ;
      'd74 : lit_code_w = 'b01111010 ;
      'd75 : lit_code_w = 'b01111011 ;
      'd76 : lit_code_w = 'b01111100 ;
      'd77 : lit_code_w = 'b01111101 ;
      'd78 : lit_code_w = 'b01111110 ;
      'd79 : lit_code_w = 'b01111111 ;
      'd80 : lit_code_w = 'b10000000 ;
      'd81 : lit_code_w = 'b10000001 ;
      'd82 : lit_code_w = 'b10000010 ;
      'd83 : lit_code_w = 'b10000011 ;
      'd84 : lit_code_w = 'b10000100 ;
      'd85 : lit_code_w = 'b10000101 ;
      'd86 : lit_code_w = 'b10000110 ;
      'd87 : lit_code_w = 'b10000111 ;
      'd88 : lit_code_w = 'b10001000 ;
      'd89 : lit_code_w = 'b10001001 ;
      'd90 : lit_code_w = 'b10001010 ;
      'd91 : lit_code_w = 'b10001011 ;
      'd92 : lit_code_w = 'b10001100 ;
      'd93 : lit_code_w = 'b10001101 ;
      'd94 : lit_code_w = 'b10001110 ;
      'd95 : lit_code_w = 'b10001111 ;
      'd96 : lit_code_w = 'b10010000 ;
      'd97 : lit_code_w = 'b10010001 ;
      'd98 : lit_code_w = 'b10010010 ;
      'd99 : lit_code_w = 'b10010011 ;
      'd100: lit_code_w = 'b10010100 ;
      'd101: lit_code_w = 'b10010101 ;
      'd102: lit_code_w = 'b10010110 ;
      'd103: lit_code_w = 'b10010111 ;
      'd104: lit_code_w = 'b10011000 ;
      'd105: lit_code_w = 'b10011001 ;
      'd106: lit_code_w = 'b10011010 ;
      'd107: lit_code_w = 'b10011011 ;
      'd108: lit_code_w = 'b10011100 ;
      'd109: lit_code_w = 'b10011101 ;
      'd110: lit_code_w = 'b10011110 ;
      'd111: lit_code_w = 'b10011111 ;
      'd112: lit_code_w = 'b10100000 ;
      'd113: lit_code_w = 'b10100001 ;
      'd114: lit_code_w = 'b10100010 ;
      'd115: lit_code_w = 'b10100011 ;
      'd116: lit_code_w = 'b10100100 ;
      'd117: lit_code_w = 'b10100101 ;
      'd118: lit_code_w = 'b10100110 ;
      'd119: lit_code_w = 'b10100111 ;
      'd120: lit_code_w = 'b10101000 ;
      'd121: lit_code_w = 'b10101001 ;
      'd122: lit_code_w = 'b10101010 ;
      'd123: lit_code_w = 'b10101011 ;
      'd124: lit_code_w = 'b10101100 ;
      'd125: lit_code_w = 'b10101101 ;
      'd126: lit_code_w = 'b10101110 ;
      'd127: lit_code_w = 'b10101111 ;
      'd128: lit_code_w = 'b10110000 ;
      'd129: lit_code_w = 'b10110001 ;
      'd130: lit_code_w = 'b10110010 ;
      'd131: lit_code_w = 'b10110011 ;
      'd132: lit_code_w = 'b10110100 ;
      'd133: lit_code_w = 'b10110101 ;
      'd134: lit_code_w = 'b10110110 ;
      'd135: lit_code_w = 'b10110111 ;
      'd136: lit_code_w = 'b10111000 ;
      'd137: lit_code_w = 'b10111001 ;
      'd138: lit_code_w = 'b10111010 ;
      'd139: lit_code_w = 'b10111011 ;
      'd140: lit_code_w = 'b10111100 ;
      'd141: lit_code_w = 'b10111101 ;
      'd142: lit_code_w = 'b10111110 ;
      'd143: lit_code_w = 'b10111111 ;
      'd144: lit_code_w = 'b110010000;
      'd145: lit_code_w = 'b110010001;
      'd146: lit_code_w = 'b110010010;
      'd147: lit_code_w = 'b110010011;
      'd148: lit_code_w = 'b110010100;
      'd149: lit_code_w = 'b110010101;
      'd150: lit_code_w = 'b110010110;
      'd151: lit_code_w = 'b110010111;
      'd152: lit_code_w = 'b110011000;
      'd153: lit_code_w = 'b110011001;
      'd154: lit_code_w = 'b110011010;
      'd155: lit_code_w = 'b110011011;
      'd156: lit_code_w = 'b110011100;
      'd157: lit_code_w = 'b110011101;
      'd158: lit_code_w = 'b110011110;
      'd159: lit_code_w = 'b110011111;
      'd160: lit_code_w = 'b110100000;
      'd161: lit_code_w = 'b110100001;
      'd162: lit_code_w = 'b110100010;
      'd163: lit_code_w = 'b110100011;
      'd164: lit_code_w = 'b110100100;
      'd165: lit_code_w = 'b110100101;
      'd166: lit_code_w = 'b110100110;
      'd167: lit_code_w = 'b110100111;
      'd168: lit_code_w = 'b110101000;
      'd169: lit_code_w = 'b110101001;
      'd170: lit_code_w = 'b110101010;
      'd171: lit_code_w = 'b110101011;
      'd172: lit_code_w = 'b110101100;
      'd173: lit_code_w = 'b110101101;
      'd174: lit_code_w = 'b110101110;
      'd175: lit_code_w = 'b110101111;
      'd176: lit_code_w = 'b110110000;
      'd177: lit_code_w = 'b110110001;
      'd178: lit_code_w = 'b110110010;
      'd179: lit_code_w = 'b110110011;
      'd180: lit_code_w = 'b110110100;
      'd181: lit_code_w = 'b110110101;
      'd182: lit_code_w = 'b110110110;
      'd183: lit_code_w = 'b110110111;
      'd184: lit_code_w = 'b110111000;
      'd185: lit_code_w = 'b110111001;
      'd186: lit_code_w = 'b110111010;
      'd187: lit_code_w = 'b110111011;
      'd188: lit_code_w = 'b110111100;
      'd189: lit_code_w = 'b110111101;
      'd190: lit_code_w = 'b110111110;
      'd191: lit_code_w = 'b110111111;
      'd192: lit_code_w = 'b111000000;
      'd193: lit_code_w = 'b111000001;
      'd194: lit_code_w = 'b111000010;
      'd195: lit_code_w = 'b111000011;
      'd196: lit_code_w = 'b111000100;
      'd197: lit_code_w = 'b111000101;
      'd198: lit_code_w = 'b111000110;
      'd199: lit_code_w = 'b111000111;
      'd200: lit_code_w = 'b111001000;
      'd201: lit_code_w = 'b111001001;
      'd202: lit_code_w = 'b111001010;
      'd203: lit_code_w = 'b111001011;
      'd204: lit_code_w = 'b111001100;
      'd205: lit_code_w = 'b111001101;
      'd206: lit_code_w = 'b111001110;
      'd207: lit_code_w = 'b111001111;
      'd208: lit_code_w = 'b111010000;
      'd209: lit_code_w = 'b111010001;
      'd210: lit_code_w = 'b111010010;
      'd211: lit_code_w = 'b111010011;
      'd212: lit_code_w = 'b111010100;
      'd213: lit_code_w = 'b111010101;
      'd214: lit_code_w = 'b111010110;
      'd215: lit_code_w = 'b111010111;
      'd216: lit_code_w = 'b111011000;
      'd217: lit_code_w = 'b111011001;
      'd218: lit_code_w = 'b111011010;
      'd219: lit_code_w = 'b111011011;
      'd220: lit_code_w = 'b111011100;
      'd221: lit_code_w = 'b111011101;
      'd222: lit_code_w = 'b111011110;
      'd223: lit_code_w = 'b111011111;
      'd224: lit_code_w = 'b111100000;
      'd225: lit_code_w = 'b111100001;
      'd226: lit_code_w = 'b111100010;
      'd227: lit_code_w = 'b111100011;
      'd228: lit_code_w = 'b111100100;
      'd229: lit_code_w = 'b111100101;
      'd230: lit_code_w = 'b111100110;
      'd231: lit_code_w = 'b111100111;
      'd232: lit_code_w = 'b111101000;
      'd233: lit_code_w = 'b111101001;
      'd234: lit_code_w = 'b111101010;
      'd235: lit_code_w = 'b111101011;
      'd236: lit_code_w = 'b111101100;
      'd237: lit_code_w = 'b111101101;
      'd238: lit_code_w = 'b111101110;
      'd239: lit_code_w = 'b111101111;
      'd240: lit_code_w = 'b111110000;
      'd241: lit_code_w = 'b111110001;
      'd242: lit_code_w = 'b111110010;
      'd243: lit_code_w = 'b111110011;
      'd244: lit_code_w = 'b111110100;
      'd245: lit_code_w = 'b111110101;
      'd246: lit_code_w = 'b111110110;
      'd247: lit_code_w = 'b111110111;
      'd248: lit_code_w = 'b111111000;
      'd249: lit_code_w = 'b111111001;
      'd250: lit_code_w = 'b111111010;
      'd251: lit_code_w = 'b111111011;
      'd252: lit_code_w = 'b111111100;
      'd253: lit_code_w = 'b111111101;
      'd254: lit_code_w = 'b111111110;
      'd255: lit_code_w = 'b111111111;
      default: lit_code_w = 'd0;
    endcase
  end
  // literal code width
  always @(*) begin
    lit_code_wd_w = 'd0;
    if (lit_dat_i <= 'd143) begin
      lit_code_wd_w = 'd8;
    end
    else begin
      lit_code_wd_w = 'd9; 
    end
  end

  // length code
  always @(*) begin
    len_code_w = 'd0;
    case(len_dat_i)
      'd3 : len_code_w = 'b0000001    ;
      'd4 : len_code_w = 'b0000010    ;
      'd5 : len_code_w = 'b0000011    ;
      'd6 : len_code_w = 'b0000100    ;
      'd7 : len_code_w = 'b0000101    ;
      'd8 : len_code_w = 'b0000110    ;
      'd9 : len_code_w = 'b0000111    ;
      'd10: len_code_w = 'b0001000    ;
      'd11: len_code_w = 'b0001001_0  ;
      'd12: len_code_w = 'b0001001_1  ;
      'd13: len_code_w = 'b0001010_0  ;
      'd14: len_code_w = 'b0001010_1  ;
      'd15: len_code_w = 'b0001011_0  ;
      'd16: len_code_w = 'b0001011_1  ;
      'd17: len_code_w = 'b0001100_0  ;
      'd18: len_code_w = 'b0001100_1  ;
      'd19: len_code_w = 'b0001101_00 ;
      'd20: len_code_w = 'b0001101_01 ;
      'd21: len_code_w = 'b0001101_10 ;
      'd22: len_code_w = 'b0001101_11 ;
      'd23: len_code_w = 'b0001110_00 ;
      'd24: len_code_w = 'b0001110_01 ;
      'd25: len_code_w = 'b0001110_10 ;
      'd26: len_code_w = 'b0001110_11 ;
      'd27: len_code_w = 'b0001111_00 ;
      'd28: len_code_w = 'b0001111_01 ;
      'd29: len_code_w = 'b0001111_10 ;
      'd30: len_code_w = 'b0001111_11 ;
      'd31: len_code_w = 'b0010000_00 ;
      'd32: len_code_w = 'b0010000_01 ;
      'd33: len_code_w = 'b0010000_10 ;
      'd34: len_code_w = 'b0010000_11 ;
      'd35: len_code_w = 'b0010001_000;
      'd36: len_code_w = 'b0010001_001;
      'd37: len_code_w = 'b0010001_010;
      'd38: len_code_w = 'b0010001_011;
      'd39: len_code_w = 'b0010001_100;
      'd40: len_code_w = 'b0010001_101;
      'd41: len_code_w = 'b0010001_110;
      'd42: len_code_w = 'b0010001_111;
      'd43: len_code_w = 'b0010010_000;
      'd44: len_code_w = 'b0010010_001;
      'd45: len_code_w = 'b0010010_010;
      'd46: len_code_w = 'b0010010_011;
      'd47: len_code_w = 'b0010010_100;
      'd48: len_code_w = 'b0010010_101;
      'd49: len_code_w = 'b0010010_110;
      'd50: len_code_w = 'b0010010_111;
      'd51: len_code_w = 'b0010011_000;
      'd52: len_code_w = 'b0010011_001;
      'd53: len_code_w = 'b0010011_010;
      'd54: len_code_w = 'b0010011_011;
      'd55: len_code_w = 'b0010011_100;
      'd56: len_code_w = 'b0010011_101;
      'd57: len_code_w = 'b0010011_110;
      'd58: len_code_w = 'b0010011_111;
      'd59: len_code_w = 'b0010100_000;
      'd60: len_code_w = 'b0010100_001;
      'd61: len_code_w = 'b0010100_010;
      'd62: len_code_w = 'b0010100_011;
      'd63: len_code_w = 'b0010100_100;
      'd64: len_code_w = 'b0010100_101;
      default: len_code_w = 'd0;
    endcase
  end
  // length code width
  always @(*) begin
    len_code_wd_w = 'd0;
    if (len_dat_i <= 'd10) begin
      len_code_wd_w = 'd7;
    end
    else if (len_dat_i <= 'd18) begin
      len_code_wd_w = 'd7 + 'd1; 
    end
    else if (len_dat_i <= 'd34) begin
      len_code_wd_w = 'd7 + 'd2;
    end
    else begin
      len_code_wd_w = 'd7 + 'd3;
    end
  end

  // distance code
  always @(*) begin
    dis_code_w = 'd0;
    case(dis_dat_i)
      'd1 : dis_code_w = 'b00000;
      'd2 : dis_code_w = 'b00001;
      'd3 : dis_code_w = 'b00010;
      'd4 : dis_code_w = 'b00011;
      'd5 : dis_code_w = 'b00100_0;
      'd6 : dis_code_w = 'b00100_1;
      'd7 : dis_code_w = 'b00101_0;
      'd8 : dis_code_w = 'b00101_1;
      'd9 : dis_code_w = 'b00110_00;
      'd10: dis_code_w = 'b00110_01;
      'd11: dis_code_w = 'b00110_10;
      'd12: dis_code_w = 'b00110_11;
      'd13: dis_code_w = 'b00111_00;
      'd14: dis_code_w = 'b00111_01;
      'd15: dis_code_w = 'b00111_10;
      'd16: dis_code_w = 'b00111_11;
      'd17: dis_code_w = 'b01000_000;
      'd18: dis_code_w = 'b01000_001;
      'd19: dis_code_w = 'b01000_010;
      'd20: dis_code_w = 'b01000_011;
      'd21: dis_code_w = 'b01000_100;
      'd22: dis_code_w = 'b01000_101;
      'd23: dis_code_w = 'b01000_110;
      'd24: dis_code_w = 'b01000_111;
      'd25: dis_code_w = 'b01001_000;
      'd26: dis_code_w = 'b01001_001;
      'd27: dis_code_w = 'b01001_010;
      'd28: dis_code_w = 'b01001_011;
      'd29: dis_code_w = 'b01001_100;
      'd30: dis_code_w = 'b01001_101;
      'd31: dis_code_w = 'b01001_110;
      'd32: dis_code_w = 'b01001_111;
      'd33: dis_code_w = 'b01010_0000;
      'd34: dis_code_w = 'b01010_0001;
      'd35: dis_code_w = 'b01010_0010;
      'd36: dis_code_w = 'b01010_0011;
      'd37: dis_code_w = 'b01010_0100;
      'd38: dis_code_w = 'b01010_0101;
      'd39: dis_code_w = 'b01010_0110;
      'd40: dis_code_w = 'b01010_0111;
      'd41: dis_code_w = 'b01010_1000;
      'd42: dis_code_w = 'b01010_1001;
      'd43: dis_code_w = 'b01010_1010;
      'd44: dis_code_w = 'b01010_1011;
      'd45: dis_code_w = 'b01010_1100;
      'd46: dis_code_w = 'b01010_1101;
      'd47: dis_code_w = 'b01010_1110;
      'd48: dis_code_w = 'b01010_1111;
      'd49: dis_code_w = 'b01011_0000;
      'd50: dis_code_w = 'b01011_0001;
      'd51: dis_code_w = 'b01011_0010;
      'd52: dis_code_w = 'b01011_0011;
      'd53: dis_code_w = 'b01011_0100;
      'd54: dis_code_w = 'b01011_0101;
      'd55: dis_code_w = 'b01011_0110;
      'd56: dis_code_w = 'b01011_0111;
      'd57: dis_code_w = 'b01011_1000;
      'd58: dis_code_w = 'b01011_1001;
      'd59: dis_code_w = 'b01011_1010;
      'd60: dis_code_w = 'b01011_1011;
      'd61: dis_code_w = 'b01011_1100;
      'd62: dis_code_w = 'b01011_1101;
      'd63: dis_code_w = 'b01011_1110;
      'd64: dis_code_w = 'b01011_1111;
      default: dis_code_w = 'd0;
    endcase
  end
  // distance code width
  always @(*) begin
    dis_code_wd_w = 'd0;
    if (dis_dat_i <= 'd4) begin
      dis_code_wd_w = 'd5;
    end
    else if (dis_dat_i <= 'd8) begin
      dis_code_wd_w = 'd5 + 'd1; 
    end
    else if (dis_dat_i <= 'd16) begin
      dis_code_wd_w = 'd5 + 'd2;
    end
    else if (dis_dat_i <= 'd32) begin
      dis_code_wd_w = 'd5 + 'd3;
    end
    else begin
      dis_code_wd_w = 'd5 + 'd4;
    end
  end


endmodule