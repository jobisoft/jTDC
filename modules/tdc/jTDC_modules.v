`default_nettype none
//-----------------------------------------------------------------
//--                                                             --
//-- Company:  University of Bonn                                --
//-- Engineer: John Bieling                                      --
//--                                                             --
//-----------------------------------------------------------------
//--                                                             --
//-- Copyright (C) 2015 John Bieling                             --
//--                                                             --
//-- This source file may be used and distributed without        --
//-- restriction provided that this copyright statement is not   --
//-- removed from the file and that any derivative work contains --
//-- the original copyright notice and the associated disclaimer.--
//--                                                             --
//--     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     --
//-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   --
//-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   --
//-- FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      --
//-- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         --
//-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    --
//-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   --
//-- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        --
//-- BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  --
//-- LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  --
//-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  --
//-- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         --
//-- POSSIBILITY OF SUCH DAMAGE.                                 --
//--                                                             --
//-----------------------------------------------------------------


module sort8 (inA,inB,inC,inD,inE,inF,inG,inH,outA,outB,outC,outD,outE,outF,outG,outH);

	parameter datawidth = 16;

	input wire [datawidth-1:0] inA;
	input wire [datawidth-1:0] inB;
	input wire [datawidth-1:0] inC;
	input wire [datawidth-1:0] inD;
	input wire [datawidth-1:0] inE;
	input wire [datawidth-1:0] inF;
	input wire [datawidth-1:0] inG;
	input wire [datawidth-1:0] inH;

	output wire [datawidth-1:0] outA;
	output wire [datawidth-1:0] outB;
	output wire [datawidth-1:0] outC;
	output wire [datawidth-1:0] outD;
	output wire [datawidth-1:0] outE;
	output wire [datawidth-1:0] outF;
	output wire [datawidth-1:0] outG;
	output wire [datawidth-1:0] outH;
	

	function [3:0] countones;
		input [7:0] pattern;
		begin
			countones = pattern[0] + pattern[1] + pattern[2] + pattern[3] + pattern[4] + pattern[5] + pattern[6] + pattern[7];
		end
	endfunction
	
	wire [7:0] h = {inA[15],inB[15],inC[15],inD[15],inE[15],inF[15],inG[15],inH[15]};
	
	//oA
	wire [datawidth-1:0] oA0 = (h[7]   == 1'b1) ? inA : 'b0;
	wire [datawidth-1:0] oA1 = (h[7:6] == 2'b1) ? inB : 'b0; 
	wire [datawidth-1:0] oA2 = (h[7:5] == 3'b1) ? inC : 'b0;
	wire [datawidth-1:0] oA3 = (h[7:4] == 4'b1) ? inD : 'b0;
	wire [datawidth-1:0] oA4 = (h[7:3] == 5'b1) ? inE : 'b0;
	wire [datawidth-1:0] oA5 = (h[7:2] == 6'b1) ? inF : 'b0;
	wire [datawidth-1:0] oA6 = (h[7:1] == 7'b1) ? inG : 'b0;
	wire [datawidth-1:0] oA7 = (h[7:0] == 8'b1) ? inH : 'b0;
	assign outA = oA0 | oA1 | oA2 | oA3 | oA4 | oA5 | oA6 | oA7;	
		
	//oB
	wire [datawidth-1:0] oB0 = (          h[7]    == 1'b1 && h[6] == 1'b1) ? inB : 'b0; //?1
	wire [datawidth-1:0] oB1 = (countones(h[7:6]) == 4'd1 && h[5] == 1'b1) ? inC : 'b0; //??1
	wire [datawidth-1:0] oB2 = (countones(h[7:5]) == 4'd1 && h[4] == 1'b1) ? inD : 'b0; //???1
	wire [datawidth-1:0] oB3 = (countones(h[7:4]) == 4'd1 && h[3] == 1'b1) ? inE : 'b0; //????1 
	wire [datawidth-1:0] oB4 = (countones(h[7:3]) == 4'd1 && h[2] == 1'b1) ? inF : 'b0; //?????1
	wire [datawidth-1:0] oB5 = (countones(h[7:2]) == 4'd1 && h[1] == 1'b1) ? inG : 'b0; //??????1
	wire [datawidth-1:0] oB6 = (countones(h[7:1]) == 4'd1 && h[0] == 1'b1) ? inH : 'b0; //???????1
	assign outB = oB0 | oB1 | oB2 | oB3 | oB4 | oB5 | oB6;	

	//oC
	wire [datawidth-1:0] oC1 = (countones(h[7:6]) == 4'd2 && h[5] == 1'b1) ? inC : 'b0; 
	wire [datawidth-1:0] oC2 = (countones(h[7:5]) == 4'd2 && h[4] == 1'b1) ? inD : 'b0;
	wire [datawidth-1:0] oC3 = (countones(h[7:4]) == 4'd2 && h[3] == 1'b1) ? inE : 'b0;
	wire [datawidth-1:0] oC4 = (countones(h[7:3]) == 4'd2 && h[2] == 1'b1) ? inF : 'b0;
	wire [datawidth-1:0] oC5 = (countones(h[7:2]) == 4'd2 && h[1] == 1'b1) ? inG : 'b0;
	wire [datawidth-1:0] oC6 = (countones(h[7:1]) == 4'd2 && h[0] == 1'b1) ? inH : 'b0;
	assign outC = oC1 | oC2 | oC3 | oC4 | oC5 | oC6;	

	//oD
	wire [datawidth-1:0] oD2 = (countones(h[7:5]) == 4'd3 && h[4] == 1'b1) ? inD : 'b0; 
	wire [datawidth-1:0] oD3 = (countones(h[7:4]) == 4'd3 && h[3] == 1'b1) ? inE : 'b0; 
	wire [datawidth-1:0] oD4 = (countones(h[7:3]) == 4'd3 && h[2] == 1'b1) ? inF : 'b0;
	wire [datawidth-1:0] oD5 = (countones(h[7:2]) == 4'd3 && h[1] == 1'b1) ? inG : 'b0;
	wire [datawidth-1:0] oD6 = (countones(h[7:1]) == 4'd3 && h[0] == 1'b1) ? inH : 'b0;
	assign outD = oD2 | oD3 | oD4 | oD5 | oD6;	

	//oE
	wire [datawidth-1:0] oE3 = (countones(h[7:4]) == 4'd4 && h[3] == 1'b1) ? inE : 'b0; 
	wire [datawidth-1:0] oE4 = (countones(h[7:3]) == 4'd4 && h[2] == 1'b1) ? inF : 'b0;
	wire [datawidth-1:0] oE5 = (countones(h[7:2]) == 4'd4 && h[1] == 1'b1) ? inG : 'b0;
	wire [datawidth-1:0] oE6 = (countones(h[7:1]) == 4'd4 && h[0] == 1'b1) ? inH : 'b0;
	assign outE = oE3 | oE4 | oE5 | oE6;	

	//oF
	wire [datawidth-1:0] oF4 = (countones(h[7:3]) == 4'd5 && h[2] == 1'b1) ? inF : 'b0;
	wire [datawidth-1:0] oF5 = (countones(h[7:2]) == 4'd5 && h[1] == 1'b1) ? inG : 'b0;
	wire [datawidth-1:0] oF6 = (countones(h[7:1]) == 4'd5 && h[0] == 1'b1) ? inH : 'b0;
	assign outF = oF4 | oF5 | oF6;	

	//oG
	wire [datawidth-1:0] oG5 = (countones(h[7:2]) == 4'd6 && h[1] == 1'b1) ? inG : 'b0;
	wire [datawidth-1:0] oG6 = (countones(h[7:1]) == 4'd6 && h[0] == 1'b1) ? inH : 'b0;
	assign outG = oG5 | oG6;	

	//oH
	assign outH = (h == 8'b1111_1111) ? inH : 'b0;

endmodule










module loadable_shiftreg8 (activecolumn,activegroup,load,lData_0,lData_1,lData_2,lData_3,lData_4,lData_5,lData_6,lData_7,data,CLK);

	parameter datawidth = 16;

	input wire CLK;

	input wire load;
	input wire activecolumn;
	input wire activegroup;
	
	input wire [datawidth-1:0] lData_0;
	input wire [datawidth-1:0] lData_1;
	input wire [datawidth-1:0] lData_2;
	input wire [datawidth-1:0] lData_3;
	input wire [datawidth-1:0] lData_4;
	input wire [datawidth-1:0] lData_5;
	input wire [datawidth-1:0] lData_6;
	input wire [datawidth-1:0] lData_7;

	output reg [datawidth-1:0] data;
	reg [datawidth-1:0] data_1;
	reg [datawidth-1:0] data_2;
	reg [datawidth-1:0] data_3;	
	reg [datawidth-1:0] data_4;
	reg [datawidth-1:0] data_5;
	reg [datawidth-1:0] data_6;
	reg [datawidth-1:0] data_7;

	reg [datawidth-1:0] slice_data_0;
	reg [datawidth-1:0] slice_data_1;
	reg [datawidth-1:0] slice_data_2;
	reg [datawidth-1:0] slice_data_3;
	reg [datawidth-1:0] slice_data_4;
	reg [datawidth-1:0] slice_data_5;
	reg [datawidth-1:0] slice_data_6;
	reg [datawidth-1:0] slice_data_7;
	
	always@(posedge CLK) 
	begin
		
		//loadabel latch
		if (load == 1'b1) 
		begin
			slice_data_0 <= lData_0;
			slice_data_1 <= lData_1;
			slice_data_2 <= lData_2;
			slice_data_3 <= lData_3;
			slice_data_4 <= lData_4;
			slice_data_5 <= lData_5;
			slice_data_6 <= lData_6;
			slice_data_7 <= lData_7;
		end

		if (activegroup == 1'b0) 
		begin
			data <= slice_data_0;
			data_1 <= slice_data_1;
			data_2 <= slice_data_2;
			data_3 <= slice_data_3;
			data_4 <= slice_data_4;
			data_5 <= slice_data_5;
			data_6 <= slice_data_6;
			data_7 <= slice_data_7;
		end else if (activecolumn == 1'b1)
		begin
			data <= data_1;
			data_1 <= data_2;
			data_2 <= data_3;
			data_3 <= data_4;
			data_4 <= data_5;
			data_5 <= data_6;
			data_6 <= data_7;
			data_7 <= 16'b0;
		end else 
		begin
			data <= data;
			data_1 <= data_1;
			data_2 <= data_2;
			data_3 <= data_3;
			data_4 <= data_4;
			data_5 <= data_5;
			data_6 <= data_6;
			data_7 <= data_7;
		end

	end		
			
endmodule










module subgroup2x8 (active,CLK,load,in00,in01,in02,in03,in04,in05,in06,in07,in08,in09,in10,in11,in12,in13,in14,in15,data,skip,more);

	parameter datawidth = 16;

	input wire [datawidth-1:0] in00;
	input wire [datawidth-1:0] in01;
	input wire [datawidth-1:0] in02;
	input wire [datawidth-1:0] in03;
	input wire [datawidth-1:0] in04;
	input wire [datawidth-1:0] in05;
	input wire [datawidth-1:0] in06;
	input wire [datawidth-1:0] in07;
	input wire [datawidth-1:0] in08;
	input wire [datawidth-1:0] in09;
	input wire [datawidth-1:0] in10;
	input wire [datawidth-1:0] in11;
	input wire [datawidth-1:0] in12;
	input wire [datawidth-1:0] in13;
	input wire [datawidth-1:0] in14;
	input wire [datawidth-1:0] in15;

	wire [datawidth-1:0] out00;
	wire [datawidth-1:0] out01;
	wire [datawidth-1:0] out02;
	wire [datawidth-1:0] out03;
	wire [datawidth-1:0] out04;
	wire [datawidth-1:0] out05;
	wire [datawidth-1:0] out06;
	wire [datawidth-1:0] out07;
	wire [datawidth-1:0] out08;
	wire [datawidth-1:0] out09;
	wire [datawidth-1:0] out10;
	wire [datawidth-1:0] out11;
	wire [datawidth-1:0] out12;
	wire [datawidth-1:0] out13;
	wire [datawidth-1:0] out14;
	wire [datawidth-1:0] out15;

	input wire load;
	input wire CLK;
	input wire active;

	output wire [datawidth-1:0] data;
	output wire more;
	output wire skip;

	//sort in groups of 4 (from here on we have 100 channels, regardles of what is defined as parameter)
	sort8 sort_0 (.inA( in00), .inB( in01), .inC( in02), .inD( in03), .inE( in04), .inF( in05), .inG( in06), .inH( in07), 
					  .outA(out00), .outB(out01), .outC(out02), .outD(out03), .outE(out04), .outF(out05), .outG(out06), .outH(out07));
	
	sort8 sort_1 (.inA( in08), .inB( in09), .inC( in10), .inD( in11), .inE( in12), .inF( in13), .inG( in14), .inH( in15),  
					  .outA(out08), .outB(out09), .outC(out10), .outD(out11), .outE(out12), .outF(out13), .outG(out14), .outH(out15));	

	//count all hits (during multicycle loading) 
	//to be faster, we do not need to use sorted_data, but data, the result will be the same
	wire [4:0] total_hits_calc =  in00[15] + in01[15] + in02[15] + in03[15] +
											in04[15] + in05[15] + in06[15] + in07[15] +
											in08[15] + in09[15] + in10[15] + in11[15] +
											in12[15] + in13[15] + in14[15] + in15[15];
	

	reg [15:0] total_hits;
	always@(total_hits_calc) 
	begin
		case (total_hits_calc)
			 5'h00 : total_hits <= 16'b0000_0000_0000_0000;
			 5'h01 : total_hits <= 16'b0000_0000_0000_0001;
			 5'h02 : total_hits <= 16'b0000_0000_0000_0011;
			 5'h03 : total_hits <= 16'b0000_0000_0000_0111;
			 5'h04 : total_hits <= 16'b0000_0000_0000_1111;
			 5'h05 : total_hits <= 16'b0000_0000_0001_1111;
			 5'h06 : total_hits <= 16'b0000_0000_0011_1111;
			 5'h07 : total_hits <= 16'b0000_0000_0111_1111;
			 5'h08 : total_hits <= 16'b0000_0000_1111_1111;
			 5'h09 : total_hits <= 16'b0000_0001_1111_1111;
			 5'h0A : total_hits <= 16'b0000_0011_1111_1111;
			 5'h0B : total_hits <= 16'b0000_0111_1111_1111;
			 5'h0C : total_hits <= 16'b0000_1111_1111_1111;
			 5'h0D : total_hits <= 16'b0001_1111_1111_1111;
			 5'h0E : total_hits <= 16'b0011_1111_1111_1111;
			 5'h0F : total_hits <= 16'b0111_1111_1111_1111;
		  default : total_hits <= 16'b1111_1111_1111_1111;
		endcase
	end


	//until here, every calculation (based on tdc_out) was done in a multicycle path
	reg [15:0] hits_current;


	always@(posedge CLK) 
	begin
		if (load == 1'b1) hits_current <= total_hits;
		else if (active == 1'b1) hits_current <= (hits_current >> 1);
	end
	assign skip = ~hits_current[0];
	assign more = hits_current[1];

	wire [datawidth-1:0] data_1;
	wire [datawidth-1:0] data_0;
	wire [1:0] toprow = {data_1[15],data_0[15]};
			
	wire activecolumn_1                     = (toprow[1] == 1'b1)                           ? 1'b1 : 1'b0;
	wire activecolumn_0                     = (toprow[1] == 1'b0 && toprow[0] == 1'b1)      ? 1'b1 : 1'b0;

	wire [datawidth-1:0] active_data_1 	= (toprow[1] == 1'b1)                           ? data_1 : 'b0;
	wire [datawidth-1:0] active_data_0 	= (toprow[1] == 1'b0 && toprow[0] == 1'b1)      ? data_0 : 'b0;
	assign data = (active_data_1 | active_data_0);


	loadable_shiftreg8 LSR_1 (
		.activecolumn(activecolumn_1),
		.activegroup(active),
		.load(load),
		.lData_0(out00),
		.lData_1(out01),
		.lData_2(out02),
		.lData_3(out03),
		.lData_4(out04),
		.lData_5(out05),
		.lData_6(out06),
		.lData_7(out07),
		.data(data_1),
		.CLK(CLK));				
	
	loadable_shiftreg8 LSR_0 (
		.activecolumn(activecolumn_0),
		.activegroup(active),
		.load(load),
		.lData_0(out08),
		.lData_1(out09),
		.lData_2(out10),
		.lData_3(out11),
		.lData_4(out12),
		.lData_5(out13),
		.lData_6(out14),
		.lData_7(out15),
		.data(data_0),
		.CLK(CLK));	
		
endmodule










module select_if_active_LUT (s1,s2,d1,d2,c1,c2,od,os,oc,CLK);

	input wire CLK;
	input wire s1;
	input wire s2;
	input wire c1;
	input wire c2;
	input wire [15:0] d1;
	input wire [15:0] d2;
	output reg [15:0] od;
	output reg os;
	output reg oc;
	
	always@(posedge CLK) 
	begin

		if (s1==1'b1) 
		begin 
			od <= d1; 		
			os <= 1'b1; 
		end else if (s2==1'b1) 
		begin 
			od <= d2; 		
			os <= 1'b1; 
		end else
		begin	
			od <= 16'b0; 	
			os <= 1'b0; 
		end

		if (c1==1'b1 || c2==1'b1) oc <= 1'b1; 
		else oc <= 1'b0; 

	end

endmodule
