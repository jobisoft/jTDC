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

module datapipe (CLK,
                 data,
                 piped_data);
 
	parameter data_width = 32;
	parameter pipe_steps = 0;
	parameter keep_register_names = "YES";
	
	input wire CLK;
	input wire [data_width-1:0] data;
	output wire [data_width-1:0] piped_data;

	genvar i;
	generate
		if (pipe_steps>0) begin

			(* KEEP = keep_register_names *) reg [data_width-1:0] pipes [pipe_steps-1:0];
			
			always@(posedge CLK) begin
				pipes[0] <= data;
			end
			
			for (i=1;i<pipe_steps;i=i+1) begin : SHIFTS
				always@(posedge CLK) begin
					pipes[i] <= pipes[i-1];
				end
			end
			
			assign piped_data = pipes[pipe_steps-1];	  

		end else begin

			assign piped_data = data;	  
		
		end
	endgenerate

endmodule
