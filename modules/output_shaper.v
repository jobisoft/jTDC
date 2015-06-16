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
