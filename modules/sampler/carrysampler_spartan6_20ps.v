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
