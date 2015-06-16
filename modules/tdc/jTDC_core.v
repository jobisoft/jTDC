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

module jTDC_core (tdc_hits, tdc_data_codes, tdc_trigger_select, tdc_reset, clock_limit, geoid, iBIT, 
                  CLK200, CLKBUS, 
                  event_fifo_readrequest, data_fifo_readrequest, event_fifo_value, data_fifo_value );

	parameter tdc_channels = 98;      //number of tdc channels (max 100)
	parameter encodedbits = 9;        //includes hit bit 			
	parameter fifocounts = 15;        //max event size: (fifocounts+1)*1024-150;	

	input wire [99:0] tdc_hits;
	input wire [tdc_channels*encodedbits-1:0] tdc_data_codes;

	input wire tdc_trigger_select;
	input wire tdc_reset;
	input wire [23:0] clock_limit;
	input wire [4:0] geoid;
	input wire [7:0] iBIT;

	input wire CLK200;
	input wire CLKBUS;

	input wire event_fifo_readrequest;
	input wire data_fifo_readrequest;
	output wire [31:0] event_fifo_value;
	output wire [31:0] data_fifo_value;

	genvar i;

	//how many 36bit wide BRAM are needed for the TDC: ceil((tdc_channels*encodedbits+32)/36)
	localparam tdc_width = 1+((tdc_channels*encodedbits+32)/36); 				
	
	//how many hits should a single event hold
	localparam max_event_size = (fifocounts+1)*1024-150;	

	wire [31:0] eventcounts;	
	wire [31:0] clkcounts;	
	wire [31:0] evententriescounts;	
	wire [31:0] tdc_slicecounts;
	reg [8:0] tdc_slicecounts_current;
	reg [31:0] final_evententriescounts;
	reg reset_evententriescounts;
	reg reset_clockcounter;

	localparam reset=0, idle=1, prepare=2, fifocheck1=3, header1=4, header2=5, w4data=6, loadslice=7, fifocheck2=8,  finish=9;
	localparam hits0=10, hits1=11, hits2=12, hits3=13, hits4=14, hits5=15, hits6=16, w4filler1=17, w4filler2=18, w4filler3=19;
	localparam w4filler4=20, filler=21, trailer=22, slicetrailer=23;
	reg [31:0] state;










	//-----------------------------------------------------------------------------
	//-- TDC Trigger --------------------------------------------------------------
	//-----------------------------------------------------------------------------

	wire tdc_trigger;
	reg tdc_trigger_request_sync;
	reg tdc_trigger_request;
	reg tdc_valid_trigger;
	
	//trigger select NIM_IN[0] or LVDS_A_IN[0]
	assign tdc_trigger = (tdc_trigger_select == 1'b0) ? tdc_hits[0] : tdc_hits[1];
	
	//this delay is needed to compensate the pipe of the tdc_events, 
	//to actually see the trigger signal in the tdc data and
	//to reset the clockcounter, so that the first new entry has a 0000 clk counts
	(* KEEP = "true" *) reg [1:0] tdc_trigger_delay;
	always@(posedge CLK200) 
	begin
		tdc_trigger_delay[0] <= tdc_trigger;
		tdc_trigger_delay[1] <= tdc_trigger_delay[0];

		reset_clockcounter <= tdc_trigger_delay[0];
		tdc_trigger_request <= tdc_trigger_delay[1];
	end










	//-----------------------------------------------------------------------------
	//-- TDC Storage --------------------------------------------------------------
	//-----------------------------------------------------------------------------

	wire [24:0] tdc_hits_first_or;
	generate
		for (i=0; i < 25; i=i+1) begin : TDC_ORHITS
			assign tdc_hits_first_or[i] = |tdc_hits[i*4+3:i*4]; 
		end
	endgenerate

	reg [24:0] event_0;
	reg [7:0] event_1;
	reg [1:0] event_2;
	reg tdc_event;
	(* KEEP = "true" *) reg [36*tdc_width-32-1:0] tdc_data_2;
	(* KEEP = "true" *) reg [36*tdc_width-32-1:0] tdc_data_1;
	(* KEEP = "true" *) reg [36*tdc_width-32-1:0] tdc_data_0;
	(* KEEP = "true" *) reg [36*tdc_width-32-1:0] tdc_data;

	always@(posedge CLK200)
	begin

			//This part is independent from actual number of channels, we have 100 hit channels, some of them are dead, we do not care
			event_0 <= tdc_hits_first_or;
			
			event_1[0] <= |event_0[ 1: 0];
			event_1[1] <= |event_0[ 3: 2];
			event_1[2] <= |event_0[ 7: 4];
			event_1[3] <= |event_0[11: 8];
			event_1[4] <= |event_0[15:12];
			event_1[5] <= |event_0[19:16];
			event_1[6] <= |event_0[22:20];
			event_1[7] <= |event_0[24:23];
				
			event_2[0] <= |event_1[3:0];
			event_2[1] <= |event_1[7:4];
								
			tdc_data_0 <= tdc_data_codes;
			tdc_data_1 <= tdc_data_0;
			tdc_data_2 <= tdc_data_1;

			tdc_event <= |event_2;
			tdc_data <= tdc_data_2;

	end


	wire [36*tdc_width-1-32:0] tdc_out;
	wire [31:0] tdc_clkout;
	
	wire [7:0] data_size;
	reg tdc_readnext;						
	(* KEEP_HIERARCHY = "true" *) BRAMTDC_256_SWITCHING #(.width(tdc_width)) BRAMTDC (
		.d({tdc_data,clkcounts}), 
		.q({tdc_out,tdc_clkout}), 
		.CLK(CLK200), 
		.tdc_event(tdc_event),
		.tdc_readnext(tdc_readnext),
		.tdc_switch(tdc_valid_trigger),
		.tdc_request(tdc_trigger_request_sync),
		.data_size(data_size));










	//-----------------------------------------------------------------------------
	//-- Add Channel Numbers And Sort Zeros Out Of BRAM Data ----------------------
	//-----------------------------------------------------------------------------

	generate

		for (i=0; i < 100; i=i+1) begin : Channel 

			wire [15:0] data;
			
			if (i<tdc_channels) 
			begin
				assign data[7:0] = {'b0,tdc_out[(i+1)*encodedbits-2:i*encodedbits]};
				assign data[15] = tdc_out[(i+1)*encodedbits-1];
			end else begin
				assign data[7:0] = 'b0;
				assign data[15] = 1'b0;
			end
			assign data[14:8] = i;		

		end

	endgenerate

	wire [15:0] gruppe_0_data;		wire gruppe_0_more;		wire gruppe_0_skip;
	wire [15:0] gruppe_1_data;		wire gruppe_1_more;		wire gruppe_1_skip;
	wire [15:0] gruppe_2_data;		wire gruppe_2_more;		wire gruppe_2_skip;
	wire [15:0] gruppe_3_data;		wire gruppe_3_more;		wire gruppe_3_skip;
	wire [15:0] gruppe_4_data;		wire gruppe_4_more;		wire gruppe_4_skip;
	wire [15:0] gruppe_5_data;		wire gruppe_5_more;		wire gruppe_5_skip;
	wire [15:0] gruppe_6_data;		wire gruppe_6_more;		wire gruppe_6_skip;
	
	subgroup2x8 subgroup_0 (
		.in00(Channel[16*0+ 0].data),
		.in01(Channel[16*0+ 1].data),
		.in02(Channel[16*0+ 2].data),
		.in03(Channel[16*0+ 3].data),
		.in04(Channel[16*0+ 4].data),
		.in05(Channel[16*0+ 5].data),
		.in06(Channel[16*0+ 6].data),
		.in07(Channel[16*0+ 7].data),
		.in08(Channel[16*0+ 8].data),
		.in09(Channel[16*0+ 9].data),
		.in10(Channel[16*0+10].data),
		.in11(Channel[16*0+11].data),
		.in12(Channel[16*0+12].data),
		.in13(Channel[16*0+13].data),
		.in14(Channel[16*0+14].data),
		.in15(Channel[16*0+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits0]),
		.data(gruppe_0_data),
		.skip(gruppe_0_skip),
		.more(gruppe_0_more));

	subgroup2x8 subgroup_1 (
		.in00(Channel[16*1+ 0].data),
		.in01(Channel[16*1+ 1].data),
		.in02(Channel[16*1+ 2].data),
		.in03(Channel[16*1+ 3].data),
		.in04(Channel[16*1+ 4].data),
		.in05(Channel[16*1+ 5].data),
		.in06(Channel[16*1+ 6].data),
		.in07(Channel[16*1+ 7].data),
		.in08(Channel[16*1+ 8].data),
		.in09(Channel[16*1+ 9].data),
		.in10(Channel[16*1+10].data),
		.in11(Channel[16*1+11].data),
		.in12(Channel[16*1+12].data),
		.in13(Channel[16*1+13].data),
		.in14(Channel[16*1+14].data),
		.in15(Channel[16*1+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits1]),
		.data(gruppe_1_data),
		.skip(gruppe_1_skip),
		.more(gruppe_1_more));	
	
	subgroup2x8 subgroup_2 (
		.in00(Channel[16*2+ 0].data),
		.in01(Channel[16*2+ 1].data),
		.in02(Channel[16*2+ 2].data),
		.in03(Channel[16*2+ 3].data),
		.in04(Channel[16*2+ 4].data),
		.in05(Channel[16*2+ 5].data),
		.in06(Channel[16*2+ 6].data),
		.in07(Channel[16*2+ 7].data),
		.in08(Channel[16*2+ 8].data),
		.in09(Channel[16*2+ 9].data),
		.in10(Channel[16*2+10].data),
		.in11(Channel[16*2+11].data),
		.in12(Channel[16*2+12].data),
		.in13(Channel[16*2+13].data),
		.in14(Channel[16*2+14].data),
		.in15(Channel[16*2+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits2]),
		.data(gruppe_2_data),
		.skip(gruppe_2_skip),
		.more(gruppe_2_more));

	subgroup2x8 subgroup_3 (
		.in00(Channel[16*3+ 0].data),
		.in01(Channel[16*3+ 1].data),
		.in02(Channel[16*3+ 2].data),
		.in03(Channel[16*3+ 3].data),
		.in04(Channel[16*3+ 4].data),
		.in05(Channel[16*3+ 5].data),
		.in06(Channel[16*3+ 6].data),
		.in07(Channel[16*3+ 7].data),
		.in08(Channel[16*3+ 8].data),
		.in09(Channel[16*3+ 9].data),
		.in10(Channel[16*3+10].data),
		.in11(Channel[16*3+11].data),
		.in12(Channel[16*3+12].data),
		.in13(Channel[16*3+13].data),
		.in14(Channel[16*3+14].data),
		.in15(Channel[16*3+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits3]),
		.data(gruppe_3_data),
		.skip(gruppe_3_skip),
		.more(gruppe_3_more));		
		
	subgroup2x8 subgroup_4 (
		.in00(Channel[16*4+ 0].data),
		.in01(Channel[16*4+ 1].data),
		.in02(Channel[16*4+ 2].data),
		.in03(Channel[16*4+ 3].data),
		.in04(Channel[16*4+ 4].data),
		.in05(Channel[16*4+ 5].data),
		.in06(Channel[16*4+ 6].data),
		.in07(Channel[16*4+ 7].data),
		.in08(Channel[16*4+ 8].data),
		.in09(Channel[16*4+ 9].data),
		.in10(Channel[16*4+10].data),
		.in11(Channel[16*4+11].data),
		.in12(Channel[16*4+12].data),
		.in13(Channel[16*4+13].data),
		.in14(Channel[16*4+14].data),
		.in15(Channel[16*4+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits4]),
		.data(gruppe_4_data),
		.skip(gruppe_4_skip),
		.more(gruppe_4_more));		
		
	subgroup2x8 subgroup_5 (
		.in00(Channel[16*5+ 0].data),
		.in01(Channel[16*5+ 1].data),
		.in02(Channel[16*5+ 2].data),
		.in03(Channel[16*5+ 3].data),
		.in04(Channel[16*5+ 4].data),
		.in05(Channel[16*5+ 5].data),
		.in06(Channel[16*5+ 6].data),
		.in07(Channel[16*5+ 7].data),
		.in08(Channel[16*5+ 8].data),
		.in09(Channel[16*5+ 9].data),
		.in10(Channel[16*5+10].data),
		.in11(Channel[16*5+11].data),
		.in12(Channel[16*5+12].data),
		.in13(Channel[16*5+13].data),
		.in14(Channel[16*5+14].data),
		.in15(Channel[16*5+15].data),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits5]),
		.data(gruppe_5_data),
		.skip(gruppe_5_skip),
		.more(gruppe_5_more));		
		
	subgroup2x8 subgroup_6 (
		.in00(Channel[16*6+ 0].data),
		.in01(Channel[16*6+ 1].data),
		.in02(Channel[16*6+ 2].data),
		.in03(Channel[16*6+ 3].data),
		.in04(16'b0),
		.in05(16'b0),
		.in06(16'b0),
		.in07(16'b0),
		.in08(16'b0),
		.in09(16'b0),
		.in10(16'b0),
		.in11(16'b0),
		.in12(16'b0),
		.in13(16'b0),
		.in14(16'b0),
		.in15(16'b0),
		.CLK(CLK200),
		.load(state[loadslice]),
		.active(state[hits6]),
		.data(gruppe_6_data),
		.skip(gruppe_6_skip),
		.more(gruppe_6_more));		










	//-----------------------------------------------------------------------------
	//-- Process tdc_trigger_request ----------------------------------------------
	//-----------------------------------------------------------------------------

	localparam  old_tdc_data_ignored=2, data_fifo_overflow=1, trigger_during_busy=0;
	
	reg [31:0] fifo_write;
	reg [31:0] fifo_count;
	reg [3:0] fifo_errors;

	reg [15:0] fifo_input_header1;
	reg [15:0] fifo_input_header2;
	reg [15:0] fifo_input_slice;
	reg [15:0] fifo_input_hits0;
	reg [15:0] fifo_input_hits1;
	reg [15:0] fifo_input_hits2;
	reg [15:0] fifo_input_hits3;
	reg [15:0] fifo_input_hits4;
	reg [15:0] fifo_input_hits5;
	reg [15:0] fifo_input_hits6;
	reg [15:0] fifo_input_filler;
	reg [15:0] fifo_input_trailer;

	wire not_enough_space_for_a_slice;

	reg [31:0] event_fifo_input;
	reg event_fifo_write;
	wire event_fifo_full;
		
	reg [7:0] tdc_slicecounts_stop;
	
	reg toggle;
	reg tbit;	
	reg [31:0] latched_evententriescounts;
	reg eventsize_too_big;

	reg [31:0] tdc_first_clockcounter;
	reg [31:0] tdc_this_clockcounter;
	wire [31:0] multicycle_calculation_of_diff;
	wire tdc_data_too_old;
	assign multicycle_calculation_of_diff = tdc_first_clockcounter - tdc_this_clockcounter;
	assign tdc_data_too_old = ((tdc_first_clockcounter - tdc_this_clockcounter) > clock_limit) ? 1'b1 : 1'b0;
	
	wire more_slices_to_come;
	assign more_slices_to_come = (tdc_slicecounts_current[8:0]>{1'b0,tdc_slicecounts_stop[7:0]}) ? 1'b0 : 1'b1; 
	
	always@(posedge CLK200) 
	begin
	
		//defaults 
		event_fifo_input <= 32'b0;		
		event_fifo_write <= 1'b0;
		
		reset_evententriescounts <= 1'b0;
		
		tdc_trigger_request_sync <= 1'b0;
		tdc_valid_trigger <= 1'b0;
		tdc_readnext <= 1'b0;

		state <= 'b0;
		fifo_write <= 'b0;
		fifo_count <= 'b0;
		
		//this FSM is not allowed to create a MUX for FIFO_input, 
		//we want to have control and do it ourselves	
		fifo_input_header1 		<= {3'b110,13'b0_0000_0000_0000};
		fifo_input_header2 		<= {3'b111,geoid[4:0],iBIT[7:0]};
		fifo_input_slice 			<= {3'b100,multicycle_calculation_of_diff[12:0]};					
		fifo_input_hits0 			<= {1'b0,gruppe_0_data[14:0]};
		fifo_input_hits1 			<= {1'b0,gruppe_1_data[14:0]};
		fifo_input_hits2 			<= {1'b0,gruppe_2_data[14:0]};
		fifo_input_hits3 			<= {1'b0,gruppe_3_data[14:0]};
		fifo_input_hits4 			<= {1'b0,gruppe_4_data[14:0]};
		fifo_input_hits5 			<= {1'b0,gruppe_5_data[14:0]};
		fifo_input_hits6 			<= {1'b0,gruppe_6_data[14:0]};
		fifo_input_filler 		<= {4'b1011,12'b0000_0000_0000};
		fifo_input_trailer 		<= {4'b1010,fifo_errors,eventcounts[7:0]};


		//we ignore the lowest bit, since the readout is 32bit wide and only half as deep
		event_fifo_input <= {eventcounts[15:0],3'b0,final_evententriescounts[13:1]};					


		//-- a trigger request can only be processed if the fifo is in state idle,
		//-- otherwise it is an error
		if (tdc_trigger_request == 1'b1 && tdc_trigger_request_sync == 1'b0)
		begin
			tdc_trigger_request_sync <= 1'b1;
			if (state[idle] == 1'b1) 
			begin
				//stuff that needs to be ressetted on each trigger
				fifo_errors[trigger_during_busy] <= 1'b0;
				tdc_valid_trigger <= 1'b1;
			end
			else fifo_errors[trigger_during_busy] <= 1'b1;
		end


		//analyse evententries
		//capture evententriescounts every other clk for multi cycle calculation, we do not care if +/- 1
		tbit <= ~tbit;
		toggle <= tbit;
		if (toggle == 1'b1) 
		begin
			if (latched_evententriescounts<max_event_size) eventsize_too_big <= 1'b0; 
			else eventsize_too_big <= 1'b1;
			latched_evententriescounts <= evententriescounts;
		end


		//forcing one-hot-encoding with exclusive(parallel) states
		if (tdc_reset == 1'b1)
		begin
			state[reset] <= 1'b1;
		end else
		case (1'b1) //synthesis full_case parallel_case
							
					state[reset] : begin
											//while tdc_reset is asserted, we do not get here
											//tdc_trigger_request_sync causes the BRAM to update its last read pointer
											tdc_trigger_request_sync <= 1'b1;
											state[idle] <= 1'b1;
										end

					 state[idle] : if (tdc_valid_trigger == 1'b1) state[prepare] <= 1'b1;
										else state[idle] <= 1'b1;

				 state[prepare] :	begin
											fifo_errors[data_fifo_overflow] <= 1'b0;
											fifo_errors[old_tdc_data_ignored] <= 1'b0;
											tdc_slicecounts_stop <= data_size;
											state[fifocheck1] <= 1'b1;
										end

			 state[fifocheck1] :	if (not_enough_space_for_a_slice == 1'b0) 
										begin
											state[header1] <= 1'b1;
											fifo_count[trailer] <= 1'b1;	//see explanation in state filler
										end
										else state[fifocheck1] <= 1'b1;
										
			 	 state[header1] : begin
											fifo_write[header1] <= 1'b1;
											state[header2] <= 1'b1;
										end
										
				 state[header2] : begin
											fifo_write[header2] <= 1'b1;
											state[w4data] <= 1'b1;
										end

  			     state[w4data] : begin
											state[loadslice] <= 1'b1;
											fifo_count[filler] <= 1'b1;	//see explanation is state filler
											tdc_first_clockcounter <= tdc_clkout; 
										end

			  state[loadslice] : begin														
											//tdc_out (coming from BRAM and going through all manipulations/sorting)
											//is valid now and contains the next/first slice
											//it is stored by questioning this state, so it is now safe to shift the
											//readpointer of the BRAM
											tdc_readnext <= 1'b1;											
											
											//the information of tdc_this_clockcounter will be used in slicetrailer	
											tdc_this_clockcounter <= tdc_clkout; 

											state[fifocheck2] <= 1'b1;
										end 

										//this state is also needed to load the groups
			 state[fifocheck2] :	if (not_enough_space_for_a_slice == 1'b0) state[hits0] <= 1'b1;
										else state[fifocheck2] <= 1'b1;

					state[hits0] : begin
											fifo_write[hits0] <= gruppe_0_data[15];
											if (gruppe_0_more == 1'b1) state[hits0] <= 1'b1; else
											//if (gruppe_1_skip == 1'b1) state[hits2] <= 1'b1; else
											state[hits1] <= 1'b1;											
										end
											
					state[hits1] :	begin
											fifo_write[hits1] <= gruppe_1_data[15];
											if (gruppe_1_more == 1'b1) state[hits1] <= 1'b1; else
											//if (gruppe_2_skip == 1'b1) state[hits3] <= 1'b1; else
											state[hits2] <= 1'b1;
										end

					state[hits2] :	begin
											fifo_write[hits2] <= gruppe_2_data[15];											
											if (gruppe_2_more == 1'b1) state[hits2] <= 1'b1; else
											//if (gruppe_3_skip == 1'b1) state[hits4] <= 1'b1; else
											state[hits3] <= 1'b1;
										end

					state[hits3] :	begin
											fifo_write[hits3] <= gruppe_3_data[15];
											if (gruppe_3_more == 1'b1) state[hits3] <= 1'b1; else
											//if (gruppe_4_skip == 1'b1) state[hits5] <= 1'b1; else
											state[hits4] <= 1'b1;
										end

					state[hits4] :	begin
											fifo_write[hits4] <= gruppe_4_data[15];
											if (gruppe_4_more == 1'b1) state[hits4] <= 1'b1; else
											//if (gruppe_5_skip == 1'b1) state[hits6] <= 1'b1; else
											state[hits5] <= 1'b1;
										end

					state[hits5] :	begin
											fifo_write[hits5] <= gruppe_5_data[15];
											if (gruppe_5_more == 1'b1) state[hits5] <= 1'b1; else
											//if (gruppe_6_skip == 1'b1) state[slicetrailer] <= 1'b1; else
											state[hits6] <= 1'b1;
										end

					state[hits6] :	begin
											fifo_write[hits6] <= gruppe_6_data[15];
											if (gruppe_6_more == 1'b1) state[hits6] <= 1'b1; else
											state[slicetrailer] <= 1'b1;
										end

		  state[slicetrailer] : begin
											//tdc_data_too_old and calculation_of_diff 
											//is a multicycle_calculation based on this_clockcounter
											//which was updated during sliceload

											//more_slices_to_come is based on tdc_slicecounts_current
											//which is updated during sliceload (see counter at bottom)

											//we always write this slicetrailer
											fifo_write[slicetrailer] <= 1'b1;

											//now what?
											if (eventsize_too_big == 1'b1 || tdc_data_too_old == 1'b1 || more_slices_to_come == 1'b0)
											begin
												state[w4filler1] <= 1'b1;
											end else
											begin
												state[loadslice] <= 1'b1;
											end

											if (eventsize_too_big == 1'b1) fifo_errors[data_fifo_overflow] <= 1'b1;
											if (tdc_data_too_old == 1'b1) fifo_errors[old_tdc_data_ignored] <= 1'b1;
										end

			  state[w4filler1] : state[w4filler2] <= 1'b1; 	//wait till evententriescounts is updated 
			  state[w4filler2] : state[w4filler3] <= 1'b1; 	//wait till evententriescounts is updated 
			  state[w4filler3] : state[w4filler4] <= 1'b1; 	//wait till evententriescounts is updated 
			  state[w4filler4] : state[filler] <= 1'b1; 		//wait till evententriescounts is updated 

				  state[filler] : begin
											//store the current evententriescounts value and calculate final evententriescounts
											//depending upon count we need to add one or two (filler + trailer)
											
											//trick: We added two extra counts in state w4data2 and idle and do not have to do anything now! Why?
											//			Since we only need half of the evententriescounts, we can ignore the lowest bit, 
											//			thus TWO possible values of finalcount will be "right": (5 = 10>>1 or 11>>1)

											// 		stored events: 10 -> real events: 8 -> filler needed: yes -> final eventcount: 10/2 = 5 ==!== stored events >> 1
											// 		stored events: 11 -> real events: 9 -> filler needed: no  -> final eventcount: 10/2 = 5 ==!== stored events >> 1
											// 		stored events: 12 -> real events:10 -> filler needed: yes -> final eventcount: 12/2 = 6 ==!== stored events >> 1
											// 		stored events: 13 -> real events:11 -> filler needed: no  -> final eventcount: 12/2 = 6 ==!== stored events >> 1
											final_evententriescounts <= evententriescounts;
											if (evententriescounts[0] == 1'b0) fifo_write[filler] <= 1'b1;
											state[trailer] <= 1'b1;
											
											//due to w4filler, there is no count in the pipeline anymore
											//we do not need to count filler and trailer -> pipeline remains empty
											//so the reset is fine (it is not piped)
										end
										

				 state[trailer] : begin
											fifo_write[trailer] <= 1'b1;
											state[finish] <= 1'b1;
										end

				  state[finish] : if (event_fifo_full == 1'b0)
										begin
											reset_evententriescounts <= 1'b1;
											event_fifo_write <= 1'b1;
											state[idle] <= 1'b1;
										end
										else state[finish] <= 1'b1;
		endcase
	end










	//-----------------------------------------------------------------------------
	//-- Generate data_fifo_input Data From Individual States Data ----------------
	//-----------------------------------------------------------------------------

	wire [15:0] fifo_data_11;	wire fifo_select_11;	 	wire fifo_counts_11;	
	wire [15:0] fifo_data_12;	wire fifo_select_12;		wire fifo_counts_12;	
	wire [15:0] fifo_data_13;	wire fifo_select_13;		wire fifo_counts_13;	
	wire [15:0] fifo_data_14;	wire fifo_select_14;		wire fifo_counts_14;	
	wire [15:0] fifo_data_15;	wire fifo_select_15;		wire fifo_counts_15;	
	wire [15:0] fifo_data_16;	wire fifo_select_16;		wire fifo_counts_16;	

	wire [15:0] fifo_data_21;	wire fifo_select_21;		wire fifo_counts_21;	
	wire [15:0] fifo_data_22;	wire fifo_select_22;		wire fifo_counts_22;	
	wire [15:0] fifo_data_23;	wire fifo_select_23;		wire fifo_counts_23;	

	//first pipe
	select_if_active_LUT select_11	(.s1(fifo_write[header1])	,.s2(fifo_write[hits6]),
												 .c1(fifo_write[header1])	,.c2(fifo_write[hits6]),
												 .d1(fifo_input_header1)	,.d2(fifo_input_hits6),
												 .od(fifo_data_11),
												 .os(fifo_select_11),
												 .oc(fifo_counts_11),
												 .CLK(CLK200));

	select_if_active_LUT select_12	(.s1(fifo_write[header2])	,.s2(fifo_write[hits5]),
												 .c1(fifo_write[header2])	,.c2(fifo_write[hits5]),
												 .d1(fifo_input_header2)	,.d2(fifo_input_hits5),
												 .od(fifo_data_12),
												 .os(fifo_select_12),
												 .oc(fifo_counts_12),
												 .CLK(CLK200));

	select_if_active_LUT select_13	(.s1(fifo_write[slicetrailer])		,.s2(fifo_write[hits4]),
												 .c1(fifo_write[slicetrailer])		,.c2(fifo_write[hits4]),
												 .d1(fifo_input_slice)					,.d2(fifo_input_hits4),
												 .od(fifo_data_13),
												 .os(fifo_select_13),
												 .oc(fifo_counts_13),
												 .CLK(CLK200));
												 
	select_if_active_LUT select_14	(.s1(fifo_write[trailer])	,.s2(fifo_write[hits3]),
												 .c1(fifo_count[trailer])	,.c2(fifo_write[hits3]),
												 .d1(fifo_input_trailer)	,.d2(fifo_input_hits3),
												 .od(fifo_data_14),
												 .os(fifo_select_14),
												 .oc(fifo_counts_14),
												 .CLK(CLK200));

	select_if_active_LUT select_15	(.s1(fifo_write[filler])	,.s2(fifo_write[hits2]),
												 .c1(fifo_count[filler])	,.c2(fifo_write[hits2]),
												 .d1(fifo_input_filler)		,.d2(fifo_input_hits2),
												 .od(fifo_data_15),
												 .os(fifo_select_15),
												 .oc(fifo_counts_15),
												 .CLK(CLK200));

	select_if_active_LUT select_16	(.s1(fifo_write[hits0])		,.s2(fifo_write[hits1]),
												 .c1(fifo_write[hits0])		,.c2(fifo_write[hits1]),
												 .d1(fifo_input_hits0)		,.d2(fifo_input_hits1),
												 .od(fifo_data_16),
												 .os(fifo_select_16),
												 .oc(fifo_counts_16),
												 .CLK(CLK200));

	//-- second pipe
	select_if_active_LUT select_21	(.s1(fifo_select_11)			,.s2(fifo_select_12),
												 .c1(fifo_counts_11)			,.c2(fifo_counts_12),
												 .d1(fifo_data_11)			,.d2(fifo_data_12),
												 .od(fifo_data_21),
												 .os(fifo_select_21),
												 .oc(fifo_counts_21),
												 .CLK(CLK200));
												 
	select_if_active_LUT select_22	(.s1(fifo_select_13)			,.s2(fifo_select_14),
												 .c1(fifo_counts_13)			,.c2(fifo_counts_14),
												 .d1(fifo_data_13)			,.d2(fifo_data_14),
												 .od(fifo_data_22),
												 .os(fifo_select_22),
												 .oc(fifo_counts_22),
												 .CLK(CLK200));

	select_if_active_LUT select_23	(.s1(fifo_select_15)			,.s2(fifo_select_16),
												 .c1(fifo_counts_15)			,.c2(fifo_counts_16),
												 .d1(fifo_data_15)			,.d2(fifo_data_16),
												 .od(fifo_data_23),
												 .os(fifo_select_23),
												 .oc(fifo_counts_23),
												 .CLK(CLK200));

	//-- third pipe
	reg [15:0] data_fifo_input;
	reg data_fifo_write;
	reg data_fifo_count;

	(* KEEP = "true" *) reg [15:0] data_fifo_input_buffer;
	(* KEEP = "true" *) reg data_fifo_write_buffer;
	always@(posedge CLK200) 
	begin
		data_fifo_count <= (fifo_counts_21 || fifo_counts_22 || fifo_counts_23);

		data_fifo_input_buffer <= (fifo_data_21 | fifo_data_22 | fifo_data_23);
		data_fifo_write_buffer <= (fifo_select_21 || fifo_select_22 || fifo_select_23);
		
		data_fifo_input <= data_fifo_input_buffer;
		data_fifo_write <= data_fifo_write_buffer;
	end










	//-----------------------------------------------------------------------------
	//-- Data FIFO ----------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	wire [31:0] transform_data_fifo_output;
	wire transform_data_fifo_read;
	wire transform_data_fifo_valid;
	
	wire [31:0] internalevent_fifo_output;
	wire internalevent_fifo_read;
	wire internalevent_fifo_empty;

	wire [31:0] data_fifo_output;
	wire data_fifo_read;
	wire data_fifo_valid;

	//this fifo is used to get from 200Mhz to 100Mhz, and from 16bit to 32bit
	data_fifo_16 transform_data_fifo (
			.rst(tdc_reset),								
			.wr_clk(CLK200),
			.rd_clk(CLKBUS),								
			.din(data_fifo_input),							// input [15 : 0] din
			.wr_en(data_fifo_write),						// input wr_en
			.rd_en(transform_data_fifo_read), 			// input rd_en
			.dout(transform_data_fifo_output), 			// output [31 : 0] dout
			.prog_full(not_enough_space_for_a_slice),						
			.valid(transform_data_fifo_valid)						
	);	

	//now we auto-empty the transform-fifo and put it into a large BRAM FIFO STACK 
	//if valid, there has been a sucessfull read request (all at 100MHz)
	generate
		for (i=0; i <= fifocounts; i=i+1) begin : FifoStacks 
			
			wire fifo_full;
			wire fifo_valid;
			wire [31:0] fifo_output;
			
			if (i == 0) 
			begin
				assign transform_data_fifo_read = ~fifo_full;
				assign fifo_output = transform_data_fifo_output;
				assign fifo_valid = transform_data_fifo_valid;
			end else begin
				//this is a large BRAM FIFO @100Mhz with 32Bit width (standard fifo)
				data_fifo_big data_fifo_storage (
				  .srst(tdc_reset),								
				  .clk(CLKBUS), 									
				  .din(FifoStacks[i-1].fifo_output),							
				  .wr_en(FifoStacks[i-1].fifo_valid),						
				  .rd_en(~fifo_full), 						
				  .dout(fifo_output), 						
				  .almost_full(FifoStacks[i-1].fifo_full),	//output signal				
				  .valid(fifo_valid)											
				);	
			end
		end
	endgenerate
	assign FifoStacks[fifocounts].fifo_full = ~data_fifo_read;
	assign data_fifo_output = FifoStacks[fifocounts].fifo_output;
	assign data_fifo_valid = FifoStacks[fifocounts].fifo_valid;
	
	//auto poll data fifo
	wire [31:0] data_fifo_value_before_manipulation;
	standard_fifo_poll DATA_FIFO_POLL ( 
		.readrequest(data_fifo_readrequest),
		.CLK(CLKBUS),
		.fifo_data(data_fifo_output),
		.fifo_read(data_fifo_read),
		.fifo_valid(data_fifo_valid),
		.reset(tdc_reset),
		.fifo_value(data_fifo_value_before_manipulation)); 

	//catch and manipulate header1 before sending it to databus
	wire [31:0] data_fifo_value_after_manipulation;
	assign data_fifo_value_after_manipulation[15:0] = data_fifo_value_before_manipulation[15:0];
	assign data_fifo_value_after_manipulation[31:16] = (data_fifo_value_before_manipulation[31:29] == 3'b110) ? {3'b110,internalevent_fifo_output[12:0]} : data_fifo_value_before_manipulation[31:16];
	assign data_fifo_value = {data_fifo_value_after_manipulation[15:0],data_fifo_value_after_manipulation[31:16]}; //endian hack
	
	//the info is no longer needed -> remove from internal_event_fifo after trailer is read from data_fifo
	wire test = (data_fifo_value_before_manipulation[31:29] == 3'b110) ? 1'b0 : 1'b1;
	signal_clipper clip_read_internal_fifo (.sig(test), .CLK(CLKBUS), .clipped_sig(internalevent_fifo_read));	










	//-----------------------------------------------------------------------------
	//-- Event FIFO ---------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	wire [31:0] event_fifo_output;
	wire event_fifo_valid;
	wire event_fifo_read;

	event_fifo_32 event_fifo (
	  .rst(tdc_reset),								
	  .wr_clk(CLK200),
	  .rd_clk(CLKBUS),
	  .din(event_fifo_input),						
	  .wr_en(event_fifo_write),					
	  .rd_en(event_fifo_read), 					
	  .dout(event_fifo_output), 					
	  .full(),
	  .valid(event_fifo_valid)						
	);
		

	standard_fifo_poll EVENT_FIFO_POLL ( 
		.readrequest(event_fifo_readrequest),
		.CLK(CLKBUS),
		.fifo_data(event_fifo_output),
		.fifo_read(event_fifo_read),
		.fifo_valid(event_fifo_valid),
		.reset(tdc_reset),
		.fifo_value(event_fifo_value)); 

	//this fifo stores everything that is stored in the real event_fifo, and is used to manipulate header1 entries during read out
	event_fifo_32_FWFT internalevent_fifo (
	  .rst(tdc_reset),								
	  .wr_clk(CLK200), 									
  	  .rd_clk(CLKBUS),
	  .din(event_fifo_input),						
	  .wr_en(event_fifo_write),					
	  .rd_en(internalevent_fifo_read), 			
	  .dout(internalevent_fifo_output), 		
	  .empty(internalevent_fifo_empty),
	  .prog_full(event_fifo_full)			
	);










	//-----------------------------------------------------------------------------
	//-- Internal Counter ---------------------------------------------------------
	//-----------------------------------------------------------------------------

	slimfast_multioption_counter #(.clip_count(0)) CLOCK_COUNTER (
		 .countClock(CLK200), 
		 .count(1'b1), 
		 .reset(tdc_reset || reset_clockcounter),  
		 .countout(clkcounts));

	slimfast_multioption_counter #(.clip_count(0)) TOTAL_EVENT_COUNTER (
		 .countClock(CLK200), 
		 .count(tdc_valid_trigger), 
		 .reset(tdc_reset), 
		 .countout(eventcounts));

	slimfast_multioption_counter #(.clip_count(0)) EVENT_ENTRIES_COUNTER (
		 .countClock(CLK200), 
		 .count(data_fifo_count),
		 .reset(reset_evententriescounts || tdc_reset),
		 .countout(evententriescounts)); 

	slimfast_multioption_counter #(.clip_count(0)) SLICE_COUNTER (
		 .countClock(CLK200), 
		 .count(state[loadslice]),
		 .reset(state[prepare]),
		 .countout(tdc_slicecounts));

	always@(posedge CLK200) 
	begin
		tdc_slicecounts_current <= tdc_slicecounts[8:0];
	end
	
endmodule
