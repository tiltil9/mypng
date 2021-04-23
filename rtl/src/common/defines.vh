//------------------------------------------------------------------------------
  //
  //  Filename      : defines.vh
  //  Description   : definitions
  //  Author        : Tingting Li
  //  Email         : 1107319548@qq.com
  //  Created       : 2021-04-14
  //
//------------------------------------------------------------------------------


`timescale 1ns/1ns

`define SIZE_W_MAX  'd1024
`define SIZE_H_MAX  'd1024
`define SIZE_W_WD   `LOG2(`SIZE_W_MAX)
`define SIZE_H_WD   `LOG2(`SIZE_H_MAX)

`define DATA_PXL_WD     'd32  // RGBA: 4 chanels
`define DATA_CHN_WD     'd8   // single chanel

`define FILTER_ENUM_WD 'd3
  // `define FILTER_ENUM_NONE  3'd0
  // `define FILTER_ENUM_SUB   3'd1
  // `define FILTER_ENUM_UP    3'd2
  // `define FILTER_ENUM_AVRG  3'd3
  // `define FILTER_ENUM_PAETH 3'd4


`define LOG2(x)    ( ((x) <= ('d1<<'d01)) ? 'd01    \
                   : ((x) <= ('d1<<'d02)) ? 'd02    \
                   : ((x) <= ('d1<<'d03)) ? 'd03    \
                   : ((x) <= ('d1<<'d04)) ? 'd04    \
                   : ((x) <= ('d1<<'d05)) ? 'd05    \
                   : ((x) <= ('d1<<'d06)) ? 'd06    \
                   : ((x) <= ('d1<<'d07)) ? 'd07    \
                   : ((x) <= ('d1<<'d08)) ? 'd08    \
                   : ((x) <= ('d1<<'d09)) ? 'd09    \
                   : ((x) <= ('d1<<'d10)) ? 'd10    \
                   : ((x) <= ('d1<<'d11)) ? 'd11    \
                   : ((x) <= ('d1<<'d12)) ? 'd12    \
                   : ((x) <= ('d1<<'d13)) ? 'd13    \
                   : ((x) <= ('d1<<'d14)) ? 'd14    \
                   : ((x) <= ('d1<<'d15)) ? 'd15    \
                   : ((x) <= ('d1<<'d16)) ? 'd16    \
                   : ((x) <= ('d1<<'d17)) ? 'd17    \
                   : ((x) <= ('d1<<'d18)) ? 'd18    \
                   : ((x) <= ('d1<<'d19)) ? 'd19    \
                   : ((x) <= ('d1<<'d20)) ? 'd20    \
                   : ((x) <= ('d1<<'d21)) ? 'd21    \
                   : ((x) <= ('d1<<'d22)) ? 'd22    \
                   : ((x) <= ('d1<<'d23)) ? 'd23    \
                   : ((x) <= ('d1<<'d24)) ? 'd24    \
                   : ((x) <= ('d1<<'d25)) ? 'd25    \
                   : ((x) <= ('d1<<'d26)) ? 'd26    \
                   : ((x) <= ('d1<<'d27)) ? 'd27    \
                   : ((x) <= ('d1<<'d28)) ? 'd28    \
                   : ((x) <= ('d1<<'d29)) ? 'd29    \
                   : ((x) <= ('d1<<'d30)) ? 'd30    \
                   : ((x) <= ('d1<<'d31)) ? 'd31    \
                   : 'd0                            \
)
