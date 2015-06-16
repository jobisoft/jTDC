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

module datalatch (CLK,
                  data,
                  latch,
                  latched_data);

	parameter data_width = 32;
	parameter clip_latch = 1;
	parameter latch_pipe_steps = 0;
	parameter input_pipe_steps = 0;
	parameter keep_register_names = "YES";
	
	input wire CLK;
	input wire latch;
	input wire [data_width-1:0] data;
	(* KEEP = keep_register_names *) output reg [data_width-1:0] latched_data;

	wire clipped_latch;
	wire final_latch;
	wire [data_width-1:0] final_data;

	generate
		if (clip_latch == 1) 
		begin
			signal_clipper latchclip (	.sig(latch),	.CLK(CLK),	.clipped_sig(clipped_latch));
		end else begin
			assign clipped_latch = latch;
		end
	endgenerate

	datapipe #(.data_width(1),				.pipe_steps(latch_pipe_steps)) latch_pipe(.data(clipped_latch),	.piped_data(final_latch),	.CLK(CLK));
	datapipe #(.data_width(data_width),	.pipe_steps(input_pipe_steps)) input_pipe(.data(data),				.piped_data(final_data),	.CLK(CLK));
	
	always@(posedge CLK)
	begin
		if (final_latch == 1'b1) latched_data <= final_data;
	end	

endmodule
