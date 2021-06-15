///////////////////////////////////////////////////////////////////////
////                                                               ////
////  Copyright (C) 2013 Synopsys, Inc.                            ////
////                                                               ////
///////////////////////////////////////////////////////////////////////
////                                                               ////
////  The 90nm Generic Library ("Library") is unsupported       ////    
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



module A1825(PADIO,VDDIO,VDD,VSSIO,VSS,CORE);

inout PADIO;
inout CORE;
inout VDDIO;
inout VDD;
inout VSSIO;
inout VSS;

endmodule


module AR1825(PADIO,VDDIO,VDD,VSSIO,VSS,CORE);

inout CORE;
inout PADIO;
inout VDDIO;
inout VDD;
inout VSSIO;
inout VSS;

endmodule


module AVDD(VDD,VSSIO,AVDD,VSS);

inout VDD;
inout VSSIO;
inout AVDD;
inout VSS;

endmodule


module AVSS(VDDIO,VDD,AVSS,VSSIO,VSS);

inout VDDIO;
inout VDD;
inout AVSS;
inout VSSIO;
inout VSS;

endmodule


module B12I1025(PADIO,VSS,EN,VDDIO,PULL_UP,VDD,VSSIO,DOUT,PULL_DOWN,DIN);

inout PADIO;
inout VSS;
input EN;
inout VDDIO;
input PULL_UP;
inout VDD;
inout VSSIO;
output DOUT;
input PULL_DOWN;
input DIN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B12ISH1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B16I1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B16ISH1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B2I1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B2ISH1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B4I1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B4ISH1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B8I1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module B8ISH1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DOUT,DIN,PULL_DOWN);

inout PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
output DOUT;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module BONDPAD(PADIO,VSS,VDDIO,VDD,VSSIO);

inout PADIO;
inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module BREAKCORE(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module CAPCORNER(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module CIOVDDIOVSS(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module CORNER(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module CVDDVSS(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module D12I1025(PADIO,VSS,EN,VDDIO,VDD,VSSIO,DIN);

output PADIO;
inout VSS;
input EN;
inout VDDIO;
inout VDD;
inout VSSIO;
input DIN; 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module D16I1025(PADIO,VSS,PULL_UP,VDDIO,EN,VDD,VSSIO,DIN,PULL_DOWN);

output PADIO;
inout VSS;
input PULL_UP;
inout VDDIO;
input EN;
inout VDD;
inout VSSIO;
input DIN;
input PULL_DOWN; 

PU_PD PU_PD  (
		   .pad     ( PADIO ),
		   .pde     ( PULL_DOWN ),
		   .pue     ( PULL_UP ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   ); 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module D2I1025(PADIO,VSS,EN,VDDIO,VDD,VSSIO,DIN);

output PADIO;
inout VSS;
input EN;
inout VDDIO;
inout VDD;
inout VSSIO;
input DIN; 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module D4I1025(PADIO,VSS,EN,VDDIO,VDD,VSSIO,DIN);

output PADIO;
inout VSS;
input EN;
inout VDDIO;
inout VDD;
inout VSSIO;
input DIN; 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module D8I1025(PADIO,VSS,EN,VDDIO,VDD,VSSIO,DIN);

output PADIO;
inout VSS;
input EN;
inout VDDIO;
inout VDD;
inout VSSIO;
input DIN; 

DRIVER DRIVER  (
		   .DIN     ( DIN ),
		   .EN      ( EN ),
		   .pad     ( PADIO ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module DIOVSSVSS(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER01(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER1(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER10(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER15(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER20(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER35(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER40(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER5(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module FILLER55(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module I1025(PADIO,VSS,VDDIO,VDD,R_EN,VSSIO,DOUT);

input PADIO;
inout VSS;
inout VDDIO;
inout VDD;
input R_EN;
inout VSSIO;
output DOUT; 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module IOVDD(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module IOVSS(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module ISH1025(PADIO,VSS,VDDIO,VDD,R_EN,VSSIO,DOUT);

input PADIO;
inout VSS;
inout VDDIO;
inout VDD;
input R_EN;
inout VSSIO;
output DOUT; 

RECEIVER RECEIVER (
		   .pad     ( PADIO ),
		   .EN      ( R_EN ),
		   .DOUT    ( DOUT ),
		   .VDD     ( VDD ),
		   .VSS     ( VSS ),
		   .VDDIO   ( VDDIO ),
		   .VSSIO   ( VSSIO )
		   );

endmodule


module VDD(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


module VSS(VSS,VDDIO,VDD,VSSIO);

inout VSS;
inout VDDIO;
inout VDD;
inout VSSIO;

endmodule


//----------Subcircuits----------//


module INPUT_BUFFER (
	pad,
	EN,
	DOUT,
	VDD,
	VSS,
	VDDIO,
	VSSIO
);

input  pad;
output DOUT;
input  EN;
inout  VDD;
inout  VSS;
inout  VDDIO;
inout  VSSIO;
			
reg    DOUT;

wire power_valid = ( VDD == 1'b1 ) && ( VSS == 1'b0 ) && ( VDDIO == 1'b1 ) && ( VSSIO == 1'b0 );

always @( power_valid or pad or EN )
begin
	if ( !power_valid || ( pad === 1'bx ) || ( EN === 1'bx ) || ( EN === 1'bz ))
		DOUT = 1'bx;
	else
		if (EN && pad === 1'bz)
			DOUT = 1'bx;
		else
			DOUT = pad;
		if (!EN)
		DOUT = 1'b0;
end
			
endmodule

module RECEIVER (
	pad,
	EN,
	DOUT,
	VDD,
	VSS,
	VDDIO,
	VSSIO
);

inout  pad;
output DOUT;
input  EN;
inout  VDD;
inout  VSS;
inout  VDDIO;
inout  VSSIO;
			
reg    DOUT;

wire power_valid = ( VDD == 1'b1 ) && ( VSS == 1'b0 ) && ( VDDIO == 1'b1 ) && ( VSSIO == 1'b0 );

always @( power_valid or pad or EN )
begin
	if ( !power_valid || ( pad === 1'bx ) || ( EN === 1'bx ) || ( EN === 1'bz ))
		DOUT = 1'bx;
	else
		if (EN && pad === 1'bz)
			DOUT = 1'bx;
		else
			DOUT = pad;
		if (!EN)
		DOUT = 1'b0;
end
			
endmodule

module DRIVER (
	DIN,
	EN,
	pad,
	VDD,
	VSS,
	VDDIO,
	VSSIO
);

input  DIN;
input  EN;
inout  pad;
inout  VDD;
inout  VSS;
inout  VDDIO;
inout  VSSIO;
	
reg    pad_driver;
wire power_valid = ( VDD == 1'b1 ) && ( VSS == 1'b0 ) && ( VDDIO == 1'b1 ) && ( VSSIO == 1'b0 );

nmos i1 (pad, pad_driver, 1'b1);

always @( power_valid or DIN or EN )
begin
	if ( !power_valid)
		pad_driver = 1'bx;
	else
		if ( DIN === 1'bx || !EN)
			pad_driver = 1'bz;
		else
			pad_driver = DIN;
end

endmodule

module PU_PD (
	pad,
	pue,
	pde,
	VDD,
	VSS,
	VDDIO,
	VSSIO
	);

inout  pad;
inout  VDD;
inout  VSS;
inout  VDDIO;
inout  VSSIO;
input  pde;
input  pue;
	
not i1 (not_pde, pde);
not i2 (not_pue, pue);
and i3 (pu_EN, not_pde, pue);
and i4 (pd_EN, pde, not_pue);

bufif1 (weak1, highz0) weakpu (pad, 1'b1, pu_EN);
bufif1 (highz1, weak0) weakpd (pad, 1'b0, pd_EN);

endmodule	


