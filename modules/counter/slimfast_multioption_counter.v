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
//-- outputwidth(32) : width of output register
//-- size(31)        : Size of counter, set from 5 to outputwidth-1. (overflow bit is extra, so max (outputwidth-1) Bit)
//-- clip_count(1)   : sets if the count signal is to be clipped
//-- clip_reset(1    : sets if the reset signal is to be clipped
//--
//-- !!! IMPORTANT !!! Include slimfast_multioption_counter.ucf

module slimfast_multioption_counter (countClock,
                                     count,
                                     reset,
                                     countout);

	parameter clip_count = 1; 
	parameter clip_reset = 1;
	parameter size = 31;
	parameter outputwidth = 32;
	
	input wire countClock;
	input wire count;
	input wire reset;

	output wire [outputwidth-1:0] countout;
	
	wire [size-3:0] highbits_this;
	wire [size-3:0] highbits_next;

	//-- Counter
	slimfast_multioption_counter_core #(.clip_count(clip_count),.clip_reset(clip_reset),.size(size),.outputwidth(outputwidth)) counter(
		.countClock(countClock),
		.count(count),
		.reset(reset),
		.highbits_this(highbits_this),
		.highbits_next(highbits_next),
		.countout(countout)
		);

	//-- pure combinatorial +1 operation (multi cycle path, this may take up to 40ns without breaking the counter)
	assign highbits_next = highbits_this + 1;
	
endmodule


module slimfast_multioption_counter_core (countClock,
                                          count,
                                          reset,
                                          highbits_this,
                                          highbits_next,
                                          countout);

	parameter clip_count = 1; 
	parameter clip_reset = 1;
	parameter size = 31;
	parameter outputwidth = 32;

	
	input wire countClock;
	input wire count;
	input wire reset;

	input wire [size-3:0] highbits_next;
	output wire [size-3:0] highbits_this; 
	
	output wire [outputwidth-1:0] countout;

												 							 
	wire final_count;
	wire final_reset;
	
	reg [2:0] fast_counts = 3'b0;
	(* KEEP = "true" *) reg [size-3:0] SFC_slow_counts = 'b0;		//SFC_ prefix to make this name unique
	wire [size-3:0] slow_counts_next;	



	//-- if an if-statement compares a value to 1 (not 1'b1), it is a generate-if
	generate

		//-- this is pure combinatorial
		//-- after change of SFC_slow_counts, the update of slow_counts_next is allowed to take
		//-- 16clk cycles of countClock
		assign highbits_this = SFC_slow_counts;
		assign slow_counts_next[size-4:0] = highbits_next[size-4:0];

		//the overflow bit is counted like all the other bits, but it cannot fall back to zero
		assign slow_counts_next[size-3] = highbits_next[size-3] || highbits_this[size-3];
	
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

	
		always@(posedge countClock)
		begin
			
			if (final_reset == 1'b1)
			begin
			
				fast_counts <= 0; 
				SFC_slow_counts <= 0;

			end else begin

				//-- uses overflow as CE, valid only one clock cycle
				if (final_count == 1'b1 && fast_counts == 3'b111) begin
					SFC_slow_counts <= slow_counts_next;
				end

				//-- uses final_count as CE
				if (final_count == 1'b1) fast_counts <= fast_counts + 1'b1; 

			end
		
		end

	endgenerate 
	
	assign countout[outputwidth-1] = SFC_slow_counts[size-3];
	assign countout[outputwidth-2:0] = {'b0,SFC_slow_counts[size-4:0],fast_counts};
	
endmodule
