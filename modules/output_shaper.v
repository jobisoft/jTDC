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

module output_shaper (
	input wire d,
	input wire [3:0] hightime,
	input wire [3:0] deadtime,
	input wire CLK,
	output wire pulse,
	input wire reset);

	wire gate_closed;
	
	output_shaper_core shape (
		.d(d && ~gate_closed),
		.hightime(hightime),
		.deadtime(deadtime),
		.CLK(CLK),
		.pulse(pulse),
		.reset(reset),
		.gate_closed(gate_closed));

endmodule


module output_shaper_core (
	input wire d,
	input wire [3:0] hightime,
	input wire [3:0] deadtime,
	input wire CLK,
	output wire pulse,
	output wire gate_closed,
	input wire reset);
	

	reg closed;
	reg signal_entered;
	reg output_pulse;

	wire delay_hightime;
	wire delay_deadtime;

	reg hightime_reset;
	reg deadtime_reset;

	always@(posedge CLK) 
	begin

		hightime_reset <= reset || delay_hightime;
		deadtime_reset <= reset || delay_deadtime;
		
		//the idea: the result of (signal_entered || closed) should be the test-condition, if new signals are allowed to enter
		//          however we want to be flexible and another - external - test-condition should be usable
		//          therfore we export (signal_entered || closed) as gate_closed and it must be manually combined with the input signal
		if (d) signal_entered <= 1'b1; else  signal_entered <= 1'b0;

		//hightime check
		if (hightime_reset == 1'b1) output_pulse <= 1'b0; else if (signal_entered == 1'b1) output_pulse <= 1'b1;

		//deadtime check
		if (deadtime_reset == 1'b1) closed <= 1'b0; else if (signal_entered == 1'b1) closed <= 1'b1;
		
	end

	assign pulse = output_pulse;
	assign gate_closed = signal_entered || closed;

	SRL16 #(.INIT(16'h0000)) HIGHTIME_DELAY (
			.D(signal_entered),
			.A0(hightime[0]),	.A1(hightime[1]),	.A2(hightime[2]),	.A3(hightime[3]),     
			.CLK(CLK),
			.Q(delay_hightime));
	SRL16 #(.INIT(16'h0000)) DEADTIME_DELAY (
			.D(delay_hightime),
			.A0(deadtime[0]),	.A1(deadtime[1]),	.A2(deadtime[2]),	.A3(deadtime[3]),     
			.CLK(CLK),
			.Q(delay_deadtime));

endmodule
