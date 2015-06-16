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



//-- The module can be configured with these parameters (defaults given in braces):
//--
//-- clip_count(1) : sets if the count signal should be clipped.
//-- clip_reset(1) : sets if the reset signal should be clipped.

module dsp_multioption_counter (countClock, count, reset, countout);

	parameter clip_count = 1; 
	parameter clip_reset = 1;
	
	input countClock;
	input count;
	input reset;
	output [31:0] countout;
   
	wire [47:0] DSPOUT;
	wire CARRYOUT;

	wire [1:0] OPMODE_X = 2'b11; // send {D,A,B} to postadder
	wire [1:0] OPMODE_Z = 2'b10; // send P to postadder


	wire final_count;
	wire final_reset;


	//same clip stage as with slimfast_counter
	generate

		if (clip_count == 0) assign final_count = count; else
		if (clip_count == 1)
		begin
			wire clipped_count;
			signal_clipper countclip (	.sig(count),	.CLK(countClock),	.clipped_sig(clipped_count));
			assign final_count = clipped_count;
		end else	begin // I added this, so that one could switch from "clipped" to "not clipped" without changing the number of flip flop stages
			reg piped_count;
			always@(posedge countClock) 
			begin
				piped_count <= count;
			end
			assign final_count = piped_count;
		end

		if (clip_reset == 0) assign final_reset = reset; else
		begin
			wire clipped_reset;
			signal_clipper resetclip (	.sig(reset),	.CLK(countClock),	.clipped_sig(clipped_reset));
			assign final_reset = clipped_reset;
		end

	endgenerate


	
	DSP48A1 #(
		.A0REG ( 0 ),
		.A1REG ( 0 ),
		.B0REG ( 0 ),
		.B1REG ( 0 ),
		.CARRYINREG ( 0 ),
		.CARRYINSEL ( "OPMODE5" ), 
		.CREG ( 0 ),
		.DREG ( 0 ),
		.MREG ( 0 ),
		.OPMODEREG ( 0 ),
		.PREG ( 1 ),
		.RSTTYPE ( "SYNC" ),
		.CARRYOUTREG ( 0 ))

	DSP48A1_SLICE (

		.CLK(countClock),
	
		//inputs
		.A(18'b0),
		//counter (31bit) should count in the upper range [47:17] to use the real overflow bit of the DSP
		.B(18'b10_00000000_00000000),	
		.C(48'b0),
		.D(18'b0),

		//CE
		.CEA(1'b0),
		.CEB(1'b0),
		.CEC(1'b0),
		.CED(1'b0),
		.CEM(1'b0),
		.CEP(final_count),
		.CEOPMODE(1'b0),
		.CECARRYIN(1'b0),

		//resets
		.RSTA(1'b0),
		.RSTB(1'b0),
		.RSTC(1'b0),
		.RSTD(1'b0),
		.RSTM(1'b0),
		.RSTP(final_reset),
		.RSTOPMODE(1'b0),
		.RSTCARRYIN(1'b0),

		//carry inputs
		.CARRYIN(1'b0),
		.PCIN(48'b0),

		//outputs
		.CARRYOUTF(CARRYOUT),	
		.CARRYOUT(),	//unconnected
		.BCOUT(),		//unconnected
		.PCOUT(),		//unconnected
		.M(),				//unconnected
		.P(DSPOUT),

		//OPMODE
		.OPMODE({4'b0000,OPMODE_Z,OPMODE_X})
		);



	//overflow is in phase with DSPOUT (DSPOUT has an internal REG)
	reg overflow;
	always@(posedge countClock) 
	begin

		if (final_reset == 1'b1) overflow <= 0;
		else overflow <= overflow || CARRYOUT;

	end			

	assign countout[30:0] = DSPOUT[47:17];
   assign countout[31] = overflow;

endmodule
