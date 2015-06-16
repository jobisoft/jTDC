`default_nettype none
//---------------------------------------------------------------------
//--                                                                 --
//-- Company:  University of Bonn                                    --
//-- Engineer: John Bieling                                          --
//--                                                                 --
//---------------------------------------------------------------------
//--                                                                 --
//-- Copyright (C) 2015 John Bieling                                 --
//--                                                                 --
//-- This program is free software; you can redistribute it and/or   --
//-- modify it under the terms of the GNU General Public License as  --
//-- published by the Free Software Foundation; either version 3 of  --
//-- the License, or (at your option) any later version.             --
//--                                                                 --
//-- This program is distributed in the hope that it will be useful, --
//-- but WITHOUT ANY WARRANTY; without even the implied warranty of  --
//-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    --
//-- GNU General Public License for more details.                    --
//--                                                                 --
//-- You should have received a copy of the GNU General Public       --
//-- License along with this program; if not, see                    --
//-- <http://www.gnu.org/licenses>.                                  --
//--                                                                 --
//---------------------------------------------------------------------

module encode_96bit_pattern (edgechoice,enable,d,CLK200,CLK400,code,tdc_hit,scaler_hit);

	genvar i;

	parameter encodedbits = 9; //including hit

	input wire CLK200;
	input wire CLK400;

	input wire [95:0] d;

	input wire edgechoice;
	input wire enable;
	
	output reg [encodedbits-1:0] code; 
	output reg tdc_hit;
	output reg scaler_hit;

	//0. stage - pipe and order in groups of 4
	generate	
		for (i=0; i < 24; i=i+1) begin : STAGE0 	//i = 0,...,23
		
			reg [3:0] pattern;
			
			always@(posedge CLK400)
			begin
				if (edgechoice == 1'b0) pattern <= d[4*i+3:4*i+0];
				                   else pattern <= ~d[4*i+3:4*i+0];
			end
			
		end 
	endgenerate	


	//1. stage - encode pattern to addr
	generate	
		for (i=0; i < 24; i=i+1) begin : STAGE1 	//i = 0,...,23
		
			reg [1:0] addr;
			reg b1111;
			reg b0000;
						
			always@(posedge CLK400)
			begin
			
					//1. look into each group of four and search for the leading edge and encode 4bit pattern to 2bit LE information
					//-- b1111 and b0000 are used later: each valid LE must be followed by !b'0000 and 4'b1111
					if (STAGE0[i].pattern == 4'b1111) b1111 <= 1'b1; else b1111 <= 1'b0;
					if (STAGE0[i].pattern == 4'b0000) b0000 <= 1'b1; else b0000 <= 1'b0;

					case (STAGE0[i].pattern)

						//1. valid (but only if followed by !b'0000 and 4'b1111)
						4'b1111: begin addr <= 2'b11; end 
						4'b1110: begin addr <= 2'b11; end 
						4'b1101: begin addr <= 2'b11; end 
						4'b1100: begin addr <= 2'b11; end 
						4'b1011: begin addr <= 2'b11; end 
						4'b1010: begin addr <= 2'b11; end 
						4'b1001: begin addr <= 2'b11; end 
						4'b1000: begin addr <= 2'b11; end 

						//2. valid (but only if followed by !b'0000 and 4'b1111)
						4'b0111: begin addr <= 2'b10; end 
						4'b0110: begin addr <= 2'b10; end 
						4'b0101: begin addr <= 2'b10; end 
						4'b0100: begin addr <= 2'b10; end 

						//3. valid (but only if followed by !b'0000 and 4'b1111)
						4'b0011: begin addr <= 2'b01; end 
						4'b0010: begin addr <= 2'b01; end 

						//4. valid (but only if followed by !b'0000 and 4'b1111)
						4'b0001: begin addr <= 2'b00; end 

						//invalid
						4'b0000: begin addr <= 2'b00; end 

					endcase
					
			end 
			
		end 
	endgenerate	



	//-- 2. stage - a valid LE is none + some + some + all
	//            - shift index by TWO and remove two first and last group
	generate	
		for (i=0; i < 21; i=i+1) begin : STAGE2 	//i = 0,...,20

			reg [1:0] addr;
			reg valid;

			always@(posedge CLK400)
			begin
					
				addr <= STAGE1[i+2].addr;
				if (STAGE1[i+3].b0000 == 1'b1 && STAGE1[i+2].b0000 == 1'b0 && STAGE1[i+1].b0000 == 1'b0 && STAGE1[i].b1111 == 1'b1) 
					valid <= 1'b1;
				else 
					valid <= 1'b0;

			end
			
		end
	endgenerate	



	//-- 3. stage - mux - first hit wins (21 groups left, cannot simply divide by two)
	generate	
		for (i=0; i < 11; i=i+1) begin : STAGE3  //i = 0,...,10

			reg valid;
			reg [2:0] addr;

			if (i==10) begin

					always@(posedge CLK400)
					begin	
						valid <= STAGE2[20].valid;
						addr <= {1'b0,STAGE2[20].addr}; 
					end

			end else begin
			
				always@(posedge CLK400)
				begin	
					
					valid <= STAGE2[2*i+1].valid || STAGE2[2*i+0].valid;
					if (STAGE2[2*i+1].valid == 1'b1) addr <= {1'b1,STAGE2[2*i+1].addr}; 
					                            else addr <= {1'b0,STAGE2[2*i+0].addr}; 

				end
			
			end
	
		end
	endgenerate	



	//-- 4. stage - mux - first hit wins (11 groups left, cannot simply divide by two)
	generate	
		for (i=0; i < 6; i=i+1) begin : STAGE4  //i = 0,...,5

			reg valid;
			reg [3:0] addr;
			
			if (i==5) begin

					always@(posedge CLK400)
					begin	
						valid <= STAGE3[10].valid;
						addr <= {1'b0,STAGE3[10].addr}; 
					end

			end else begin
			
					always@(posedge CLK400)
					begin	
						
						valid <= STAGE3[2*i+1].valid || STAGE3[2*i+0].valid;
						if (STAGE3[2*i+1].valid == 1'b1) addr <= {1'b1,STAGE3[2*i+1].addr}; 
						                            else addr <= {1'b0,STAGE3[2*i+0].addr}; 

					end

			end
			
		end
	endgenerate	



	//-- 5. stage - mux again - first hit wins
	generate	
		for (i=0; i < 3; i=i+1) begin : STAGE5  //i = 0,...,2

			reg valid;
			reg [4:0] addr;
			always@(posedge CLK400)
			begin	
													 
				//first hit wins
				valid <= STAGE4[2*i+1].valid || STAGE4[2*i+0].valid;
				if (STAGE4[2*i+1].valid == 1'b1) addr <= {1'b1,STAGE4[2*i+1].addr}; 
				                            else addr <= {1'b0,STAGE4[2*i+0].addr}; 

			end
	
		end
	endgenerate	
	
	
	
	//-- 6. stage - we have 3 groups left
	//            - if a group is valid, there is a LE somewhere inside the group (addr of that group knows where)

	reg [4:0] addr_2;
	reg [4:0] addr_1;
	reg [4:0] addr_0;

	reg [6:0] exclusive_addr_2;
	reg [6:0] exclusive_addr_1;
	reg [6:0] exclusive_addr_0;
	
	reg [2:0] hitmap;
	reg [1:0] lowhit;
	reg hit;
	
	reg hit_2A;
	reg hit_2B;
	reg [6:0] addr_2A;
	reg [6:0] addr_2B;

	reg Transition400_hit_A;
	reg Transition400_hit_B;
	reg [6:0] Transition400_addr_A;
	reg [6:0] Transition400_addr_B;

	always@(posedge CLK400)
	begin
		
		//generate hitmap for final mux (reduce signals) and enforce a double hit protection - he should pack this into LUT6
		if (STAGE5[2].valid == 1'b1 && lowhit[1] == 1'b0) begin hitmap <= 3'b110; lowhit <= 2'b00; end else
		if (STAGE5[1].valid == 1'b1 && lowhit[0] == 1'b0) begin hitmap <= 3'b101; lowhit <= 2'b10; end else
		if (STAGE5[0].valid == 1'b1)                      begin hitmap <= 3'b100; lowhit <= 2'b11; end else
		                                                  begin hitmap <= 3'b000; lowhit <= 2'b00; end

		//pipe addr parallel to creating hitmap
		//addr_3 <= STAGE5[3].addr;
		addr_2 <= STAGE5[2].addr;
		addr_1 <= STAGE5[1].addr;
		addr_0 <= STAGE5[0].addr;

		//final "mux" - set all addr to zero, except the one which wins, also add group addr
		if (hitmap == 3'b110) exclusive_addr_2 <= {2'b10,addr_2}; else exclusive_addr_2 <= 0;
		if (hitmap == 3'b101) exclusive_addr_1 <= {2'b01,addr_1}; else exclusive_addr_1 <= 0;
		if (hitmap == 3'b100) exclusive_addr_0 <= {2'b00,addr_0}; else exclusive_addr_0 <= 0;
		hit <= hitmap[2];
		
		//hit and exclusive_addr are in phase, 
		//store this and the last hit result, CLK1 will check both and will take the first one
		hit_2A <= hit;
		addr_2A <= {exclusive_addr_2 | exclusive_addr_1 | exclusive_addr_0};

		hit_2B <= hit_2A;
		addr_2B <= addr_2A;
	
		Transition400_hit_A <= hit_2A;
		Transition400_hit_B <= hit_2B;
		Transition400_addr_A <= addr_2A;
		Transition400_addr_B <= addr_2B;

	end


	reg Transition200_hit_A;
	reg Transition200_hit_B;
	reg [6:0] Transition200_addr_A;
	reg [6:0] Transition200_addr_B;
	
	//cross clock
	always@(posedge CLK200)
	begin

		//just copy across clock domain
		Transition200_hit_A <= Transition400_hit_A;
		Transition200_hit_B <= Transition400_hit_B;
		Transition200_addr_A <= Transition400_addr_A;
		Transition200_addr_B <= Transition400_addr_B;
			
		//take the first one
		if (Transition200_hit_B == 1'b1) begin
			scaler_hit <= Transition200_hit_B;
			tdc_hit <= Transition200_hit_B & enable;
			code <= {Transition200_hit_B & enable,1'b1,Transition200_addr_B};
		end else begin
			scaler_hit <= Transition200_hit_A;
			tdc_hit <= Transition200_hit_A & enable;
			code <= {Transition200_hit_A & enable,1'b0,Transition200_addr_A};
		end
	end

endmodule
