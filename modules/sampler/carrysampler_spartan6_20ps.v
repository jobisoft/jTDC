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

module CHAIN_CELL (CINIT, CI, CO, DO, CLK);

	output wire [3:0] DO;
	output wire CO;
	input wire CI;
	input wire CLK;
	input wire CINIT;	
		
	wire [3:0] carry_out;

	CARRY4 CARRY4_inst (
	  .CO(carry_out),     // 4-bit carry out
	  .O(),               // 4-bit carry chain XOR data out
	  .CI(CI),            // 1-bit carry cascade input
	  .CYINIT(CINIT),     // 1-bit carry initialization
	  .DI(),              // 4-bit carry-MUX data in
	  .S(4'b1111)         // 4-bit carry-MUX select input
	);
	assign CO = carry_out[3];
			
	(* BEL = "FFD" *) FDCE #(.INIT(1'b0)) TDL_FF_D (.D(carry_out[3]), .Q(DO[3]), .C(CLK), .CE(1'b1), .CLR(1'b0));
	(* BEL = "FFC" *) FDCE #(.INIT(1'b0)) TDL_FF_C (.D(carry_out[2]), .Q(DO[2]), .C(CLK), .CE(1'b1), .CLR(1'b0));
	(* BEL = "FFB" *) FDCE #(.INIT(1'b0)) TDL_FF_B (.D(carry_out[1]), .Q(DO[1]), .C(CLK), .CE(1'b1), .CLR(1'b0));
	(* BEL = "FFA" *) FDCE #(.INIT(1'b0)) TDL_FF_A (.D(carry_out[0]), .Q(DO[0]), .C(CLK), .CE(1'b1), .CLR(1'b0));

endmodule



module carry_sampler_spartan6 (d, q, CLK);

	parameter bits = 74;
	parameter resolution = 1;
	
	input wire d;
	input wire CLK;
	output wire [bits-1:0] q;

	wire [(bits*resolution/4)-1:0] connect;
	wire [bits*resolution-1:0] register_out;
	
	genvar i,j;
	generate
	
		CHAIN_CELL FirstCell(
		  .DO({register_out[2],register_out[3],register_out[0],register_out[1]}),
		  .CINIT(d),
		  .CI(1'b0),
		  .CO(connect[0]),
		  .CLK(CLK)
		);			
	
		for (i=1; i < bits*resolution/4; i=i+1) begin : carry_chain			
			CHAIN_CELL MoreCells(
			  .DO({register_out[4*i+2],register_out[4*i+3],register_out[4*i+0],register_out[4*i+1]}),	//swapped to avoid empty bins
			  .CINIT(1'b0),
			  .CI(connect[i-1]),
			  .CO(connect[i]),
			  .CLK(CLK)
			);			
		end	

		for (j=0; j < bits; j=j+1) begin : carry_sampler	
			assign q[j] = register_out[j*resolution];
		end
		
	endgenerate
	
endmodule
