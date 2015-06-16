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
