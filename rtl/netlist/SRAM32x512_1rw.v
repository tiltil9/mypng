///////////////////////////////////////////////////////////////////////
////                                                               ////
////  Copyright (C) 2013-2016 Synopsys, Inc.                       ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
////                                                               ////
////  The 90nm Generic Library ("Library") is unsupported          ////    
////  Confidential Information of Synopsys, Inc. ("Synopsys")      ////    
////  provided to you as Documentation under the terms of the      ////    
////  End User Software License Agreement between you or your      ////    
////  employer and Synopsys ("License Agreement") and you agree    ////    
////  not to distribute or disclose the Library without the        ////    
////  prior written consent of Synopsys. The Library IS NOT an     ////    
////  item of Licensed Software or Licensed Product under the      ////    
////  License Agreement.  Synopsys and/or its licensors own        ////    
////  and shall retain all right, title and interest in and        ////    
////  to the Library and all modifications thereto, including      ////    
////  all intellectual property rights embodied therein. All       ////    
////  rights in and to any Library modifications you make are      ////    
////  hereby assigned to Synopsys. If you do not agree with        ////    
////  this notice, including the disclaimer below, then you        ////    
////  are not authorized to use the Library.                       ////    
////                                                               ////  
////                                                               ////      
////  THIS LIBRARY IS BEING DISTRIBUTED BY SYNOPSYS SOLELY ON AN   ////
////  "AS IS" BASIS, WITH NO INTELLECUTAL PROPERTY                 ////
////  INDEMNIFICATION AND NO SUPPORT. ANY EXPRESS OR IMPLIED       ////
////  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED       ////
////  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR   ////
////  PURPOSE ARE HEREBY DISCLAIMED. IN NO EVENT SHALL SYNOPSYS    ////
////  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     ////
////  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      ////
////  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;     ////
////  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)     ////
////  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN    ////
////  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE    ////
////  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS      ////
////  DOCUMENTATION, EVEN IF ADVISED OF THE POSSIBILITY OF         ////
////  SUCH DAMAGE.                                                 //// 		
////                                                               ////  
/////////////////////////////////////////////////////////////////////// 
////                                                               ////
////  The data contained in the file is created for educational    //// 
////  and training purposes only and  is not recommended           ////
////  for fabrication                                              ////
////                                                               ////
///////////////////////////////////////////////////////////////////////


/*********************************************************************
*  SAED_EDK90nm_SRAM : SRAM32x512_1rw Verilog description            *
*  ---------------------------------------------------------------   *
*  Filename      : SRAM32x512_1rw.v                                  *
*  SRAM name     : SRAM32x512_1rw                                    *
*  Word width    : 32    bits                                        *
*  Word number   : 512                                               *
*  Adress width  : 9     bits                                        *
**********************************************************************/

`timescale 1ns/100fs

`define numAddr 9
`define numWords 512
`define wordLength 32


module SRAM32x512_1rw (A,CE,WEB,OEB,CSB,I,O);

input 				CE;
input 				WEB;
input 				OEB;
input 				CSB;

input 	[`numAddr-1:0] 		A;
input 	[`wordLength-1:0] 	I;
output 	[`wordLength-1:0] 	O;

/*reg   [`wordLength-1:0]   	memory[`numWords-1:0];*/
/*reg  	[`wordLength-1:0]	data_out;*/
wire 	[`wordLength-1:0] 	O;

wire 				RE;
wire 				WE;

SRAM32x512_1rw_1bit sram_IO0 ( CE, WEB,  A, OEB, CSB, I[0], O[0]);
SRAM32x512_1rw_1bit sram_IO1 ( CE, WEB,  A, OEB, CSB, I[1], O[1]);
SRAM32x512_1rw_1bit sram_IO2 ( CE, WEB,  A, OEB, CSB, I[2], O[2]);
SRAM32x512_1rw_1bit sram_IO3 ( CE, WEB,  A, OEB, CSB, I[3], O[3]);
SRAM32x512_1rw_1bit sram_IO4 ( CE, WEB,  A, OEB, CSB, I[4], O[4]);
SRAM32x512_1rw_1bit sram_IO5 ( CE, WEB,  A, OEB, CSB, I[5], O[5]);
SRAM32x512_1rw_1bit sram_IO6 ( CE, WEB,  A, OEB, CSB, I[6], O[6]);
SRAM32x512_1rw_1bit sram_IO7 ( CE, WEB,  A, OEB, CSB, I[7], O[7]);
SRAM32x512_1rw_1bit sram_IO8 ( CE, WEB,  A, OEB, CSB, I[8], O[8]);
SRAM32x512_1rw_1bit sram_IO9 ( CE, WEB,  A, OEB, CSB, I[9], O[9]);
SRAM32x512_1rw_1bit sram_IO10 ( CE, WEB,  A, OEB, CSB, I[10], O[10]);
SRAM32x512_1rw_1bit sram_IO11 ( CE, WEB,  A, OEB, CSB, I[11], O[11]);
SRAM32x512_1rw_1bit sram_IO12 ( CE, WEB,  A, OEB, CSB, I[12], O[12]);
SRAM32x512_1rw_1bit sram_IO13 ( CE, WEB,  A, OEB, CSB, I[13], O[13]);
SRAM32x512_1rw_1bit sram_IO14 ( CE, WEB,  A, OEB, CSB, I[14], O[14]);
SRAM32x512_1rw_1bit sram_IO15 ( CE, WEB,  A, OEB, CSB, I[15], O[15]);
SRAM32x512_1rw_1bit sram_IO16 ( CE, WEB,  A, OEB, CSB, I[16], O[16]);
SRAM32x512_1rw_1bit sram_IO17 ( CE, WEB,  A, OEB, CSB, I[17], O[17]);
SRAM32x512_1rw_1bit sram_IO18 ( CE, WEB,  A, OEB, CSB, I[18], O[18]);
SRAM32x512_1rw_1bit sram_IO19 ( CE, WEB,  A, OEB, CSB, I[19], O[19]);
SRAM32x512_1rw_1bit sram_IO20 ( CE, WEB,  A, OEB, CSB, I[20], O[20]);
SRAM32x512_1rw_1bit sram_IO21 ( CE, WEB,  A, OEB, CSB, I[21], O[21]);
SRAM32x512_1rw_1bit sram_IO22 ( CE, WEB,  A, OEB, CSB, I[22], O[22]);
SRAM32x512_1rw_1bit sram_IO23 ( CE, WEB,  A, OEB, CSB, I[23], O[23]);
SRAM32x512_1rw_1bit sram_IO24 ( CE, WEB,  A, OEB, CSB, I[24], O[24]);
SRAM32x512_1rw_1bit sram_IO25 ( CE, WEB,  A, OEB, CSB, I[25], O[25]);
SRAM32x512_1rw_1bit sram_IO26 ( CE, WEB,  A, OEB, CSB, I[26], O[26]);
SRAM32x512_1rw_1bit sram_IO27 ( CE, WEB,  A, OEB, CSB, I[27], O[27]);
SRAM32x512_1rw_1bit sram_IO28 ( CE, WEB,  A, OEB, CSB, I[28], O[28]);
SRAM32x512_1rw_1bit sram_IO29 ( CE, WEB,  A, OEB, CSB, I[29], O[29]);
SRAM32x512_1rw_1bit sram_IO30 ( CE, WEB,  A, OEB, CSB, I[30], O[30]);
SRAM32x512_1rw_1bit sram_IO31 ( CE, WEB,  A, OEB, CSB, I[31], O[31]);


endmodule


module SRAM32x512_1rw_1bit (CE_i, WEB_i,  A_i, OEB_i, CSB_i, I_i, O_i);

input CSB_i;
input OEB_i;
input CE_i;
input WEB_i;

input 	[`numAddr-1:0] 	A_i;
input 	[0:0] I_i;

output 	[0:0] O_i;

reg 	[0:0]O_i;
reg    	[0:0]  	memory[`numWords-1:0];
reg  	[0:0]	data_out;


// Write Mode
and u1 (RE, ~CSB_i,  WEB_i);
and u2 (WE, ~CSB_i, ~WEB_i);


always @ (posedge CE_i) 
	if (RE)
		data_out = memory[A_i];
always @ (posedge CE_i) 
	if (WE)
		memory[A_i] = I_i;
		

always @ (data_out or OEB_i)
	if (!OEB_i) 
		O_i = data_out;
	else
		O_i =  1'bz;


endmodule


