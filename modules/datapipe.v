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
