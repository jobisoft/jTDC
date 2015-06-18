`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
//                                                                             
//  Company: University of Bonn                                                
//  Engineer: John Bieling                                                     
//                                                                                                                                                         
//  Sample implementation of jTDC using Spartan6 on
//  ELB VFB6 board with LVDS inputs
//                                                                                                                                                         
//////////////////////////////////////////////////////////////////////////////////

module jTDCv6 (

	inout wire [31:0] D_INT,
	input wire [15:0] A_INT,
	input wire WRITE_INT,
	input wire READ_INT,
	output wire DTACK_INT,

	input wire CLK,

	inout wire SCL_General,
	inout wire SDA_General,

	output wire [7:0] USER_LED,
	input wire [7:0] Pushbutton,
	input wire [1:0] Differential_IN,
	inout wire [73:0] FPGA_SPARE,
	input wire [3:0] NIM_IN,
	output wire [3:0] NIM_OUT,
	
	inout wire [73:0] MEZ_A,
	inout wire [73:0] MEZ_B,
	inout wire [73:0] MEZ_C,
	input wire [5:0] ID_A,
	input wire [5:0] ID_B,
	input wire [5:0] ID_C);










	//-----------------------------------------------------------------------------
	//-- Basic Setup --------------------------------------------------------------
	//-----------------------------------------------------------------------------

	parameter fw = 8'h22;

	parameter resolution = 2;       //readout every second carry step
	parameter bits = 96;            //empirical value for resolution=2 on VFB6
	parameter encodedbits = 9;      //includes hit bit

	parameter fifocounts = 15;      //max event size: (fifocounts+1)*1024-150;

	parameter tdc_channels = 98;    //number of tdc channels (max 100, see mapping below)
	parameter scaler_channels = 98; //number of scaler channels

	genvar i;










	//-----------------------------------------------------------------------------
	//-- IO cards Setup for VFB6 board --------------------------------------------
	//-----------------------------------------------------------------------------

	wire [31:0] LVDS_A_IN; 
	wire [31:0] LVDS_B_IN;
	wire [31:0] LVDS_C_IN;

	mez_lvds_in lvds_a_in (.MEZ(MEZ_A[73:0]),.data(LVDS_A_IN));
	mez_lvds_in lvds_b_in (.MEZ(MEZ_B[73:0]),.data(LVDS_B_IN));
	mez_lvds_in lvds_c_in (.MEZ(MEZ_C[73:0]),.data(LVDS_C_IN));









	//-----------------------------------------------------------------------------
	//-- CLK Setup for Spartan6 ---------------------------------------------------
	//-----------------------------------------------------------------------------

	wire CLKBUS;
	wire CLK200;
	wire CLK400;
	pll_vfb6_400 PLL_TDC (
		.CLKIN(CLK), 
		.CLK1(CLKBUS), 
		.CLK2(CLK200),
		.CLK4(CLK400));










	//---------------------------------------------------------------------------------
	//-- VME-BUS Setup for VFB6 board (res. addr: h0000, h0004, h0008, h0010, h0014) --
	//---------------------------------------------------------------------------------

	wire [31:0] statusregister;
	wire [31:0] databus;
	wire [15:0] addressbus;
	wire readsignal;
	wire writesignal;

	assign statusregister [7:0]   = 8'b00000001;      //-- Firmware version
	assign statusregister [13:8]  = 6'b000001;        //-- Firmware type
	//-- For REV B boards
	assign statusregister [19:14] = ID_A;             //-- Board type Mezzanine_A
	assign statusregister [25:20] = ID_B;             //-- Board type Mezzanine_B
	assign statusregister [31:26] = ID_C;             //-- Board type Mezzanine_C

	bus_interface_vfb6 BUS_INT (
		.board_databus(D_INT),
		.board_address(A_INT),
		.board_read(READ_INT),
		.board_write(WRITE_INT),
		.board_dtack(DTACK_INT),
		.CLK(CLKBUS),
		.statusregister(statusregister),
		.internal_databus(databus),
		.internal_address(addressbus),
		.internal_read(readsignal),
		.internal_write(writesignal));










	//-----------------------------------------------------------------------------
	//-- I2C Setup for VFB6 board (res. addr: h0030, h0034, h0038, h003C, h0040) --
	//-- not needed for actual jTDC, just an additional feature of the VFB6      --
	//-----------------------------------------------------------------------------

	i2c_interface I2C_INT (
		.databus(databus),
		.addressbus(addressbus),
		.CLK(CLKBUS),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.SCL_General(SCL_General),
		.SDA_General(SDA_General));










	//-----------------------------------------------------------------------------
	//-- VME Control Register A ---------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "true" *) wire [31:0] config_register_A;
	rw_register #(.myaddress(16'h0020)) VME_CONFIG_REGISTER_A ( 
		.databus(databus),
		.addressbus(addressbus),
		.readsignal(readsignal),
		.writesignal(writesignal),
		.CLK(CLKBUS),
		.registerbits(config_register_A));

	wire [4:0] geoid = config_register_A[4:0];
	wire dutycycle = config_register_A[5];
	wire edgechoice = config_register_A[6];
	wire tdc_trigger_select = config_register_A[7];
	wire [23:0] clock_limit = config_register_A[31:8];










	//-----------------------------------------------------------------------------
	//-- VME Control Register B ---------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "TRUE" *) wire [31:0] config_register_B;
	rw_register #(.myaddress(16'h0028)) VME_CONFIG_REGISTER_B ( 
		.databus(databus),
		.addressbus(addressbus),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.CLK(CLKBUS),
		.registerbits(config_register_B)); 
	
	wire [8:0] busyshift = config_register_B[8:0];					
	wire stop_counting_on_busy = config_register_B[9];
	wire [4:0] busyextend = config_register_B[15:11];		
	wire [3:0] hightime = config_register_B[19:16];
	wire [3:0] deadtime = config_register_B[23:20];
	wire [2:0] trigger_group_0 = config_register_B[26:24];
	wire [2:0] trigger_group_1 = config_register_B[29:27];
	wire disable_external_latch = config_register_B[30];
	wire fake_mode = config_register_B[31];










	//-----------------------------------------------------------------------------
	//-- VME Trigger Register -----------------------------------------------------
	//-----------------------------------------------------------------------------

	wire [7:0] iFW = fw;
	wire [7:0] iCH = tdc_channels;
	wire [7:0] iBIT = encodedbits-1;           //the hit-bit is not pushed into the fifo
	wire [7:0] iM = 8'h34;
	wire [31:0] trigger_register_wire;
	toggle_register #(.myaddress(16'h0024)) VME_TRIGGER_REGISTER (
		.databus(databus),
		.addressbus(addressbus),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.CLK(CLKBUS),
		.info({iCH,iBIT,iM,iFW}),	
		.registerbits(trigger_register_wire)); 

	//cross clock domain
	reg [31:0] trigger_register;
	always@(posedge CLK200) 
	begin
		trigger_register <= trigger_register_wire;
	end

	//-- toggle bit 0: tdc_reset, make tdc_reset multiple cycles long
	wire tdc_reset_start = trigger_register[0];
	reg [3:0] tdc_reset_counter = 4'b0000;
	reg tdc_reset;
	reg tdc_reset_buffer;
	always@(posedge CLKBUS) 
	begin
		tdc_reset <= tdc_reset_buffer;
		if (tdc_reset_counter == 4'b0000)
		begin
			tdc_reset_buffer <= 1'b0;
			if (tdc_reset_start == 1'b1) tdc_reset_counter <= 4'b1111;
		end else begin
			tdc_reset_buffer <= 1'b1;
			tdc_reset_counter <= tdc_reset_counter - 1;
		end
	end
   
	//-- toggle bit 1: vme_counter_reset
	wire vme_counter_reset;
 	datapipe #(.data_width(1),.pipe_steps(2)) counter_reset_pipe ( 
		.data(trigger_register[1]), 				
		.piped_data(vme_counter_reset),
		.CLK(CLK200));  

	//-- toggle bit 2: vme_counter_latch
	wire vme_counter_latch;
	datapipe #(.data_width(1),.pipe_steps(1)) counter_latch_pipe ( 
		.data(trigger_register[2]), 				
		.piped_data(vme_counter_latch),
		.CLK(CLK200));

	//-- toggle bit 3: output_reset
	wire output_reset = trigger_register[3];

	//-- toggle bit 6: generate fake data input for busyshift measurement
	wire fake_data;
	signal_clipper fake_data_clip ( .sig(trigger_register[6]), .CLK(CLK200), .clipped_sig(fake_data));










	//-----------------------------------------------------------------------------
	//-- Enable Register ----------------------------------------------------------
	//-----------------------------------------------------------------------------

	(* KEEP = "TRUE" *) wire [95:0] enable_register;
	rw_register #(.myaddress(16'h2000)) VME_ENABLE_REGISTER_A ( 
		.databus(databus),
		.addressbus(addressbus),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.CLK(CLKBUS),
		.registerbits(enable_register[31:0])); 
	rw_register #(.myaddress(16'h2004)) VME_ENABLE_REGISTER_B ( 
		.databus(databus),
		.addressbus(addressbus),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.CLK(CLKBUS),
		.registerbits(enable_register[63:32])); 
	rw_register #(.myaddress(16'h2008)) VME_ENABLE_REGISTER_C ( 
		.databus(databus),
		.addressbus(addressbus),
		.writesignal(writesignal),
		.readsignal(readsignal),
		.CLK(CLKBUS),
		.registerbits(enable_register[95:64])); 










	//-----------------------------------------------------------------------------
	//-- Busy & Latch ------------------------------------------------------
	//-----------------------------------------------------------------------------

	wire raw_busy;	
	wire latch;
	reg busy;		
	reg counter_latch;	
	reg counter_reset;

	//the leading edge of the "busy & latch" signal is the actual latch, which is used only to latch the input scaler
	//while the "busy & latch" signal is asserted, the input scaler will not count (if stop_counting_on_busy is set)
	leading_edge_extractor LATCH_EXTRACTOR (.sig(NIM_IN[0]), .CLK(CLK200), .unclipped_extend(busyextend), .clipped_sig(latch), .unclipped_sig(raw_busy) );
	always@(posedge CLK200)
	begin
		busy <= stop_counting_on_busy & raw_busy;
		counter_latch <= vme_counter_latch | (latch & ~disable_external_latch);
		counter_reset <= vme_counter_reset;
	end










	//-----------------------------------------------------------------------------
	//-- Map Inputs To 100 TDC Channels -------------------------------------------
	//-----------------------------------------------------------------------------

	wire [99:0] tdc_enable;
	wire [99:0] tdc_channel;
	
	assign tdc_channel[0] = NIM_IN[0];
	assign tdc_enable[0] = 1'b1;

	assign tdc_enable[96:1] = enable_register[95:0];
	assign tdc_channel[32:1] = (edgechoice == 1'b0) ? LVDS_A_IN[31:0] : ~LVDS_A_IN[31:0];
	assign tdc_channel[64:33] = (edgechoice == 1'b0) ? LVDS_B_IN[31:0] : ~LVDS_B_IN[31:0];
	assign tdc_channel[96:65] = (edgechoice == 1'b0) ? LVDS_C_IN[31:0] : ~LVDS_C_IN[31:0];

	assign tdc_channel[97] = NIM_IN[2];
	assign tdc_enable[97] = 1'b1;










	//-----------------------------------------------------------------------------
	//-- Sampling -----------------------------------------------------------------
	//-----------------------------------------------------------------------------

	wire [99:0] tdc_hits;
	wire [tdc_channels-1:0] scaler_hits;
	wire [tdc_channels*encodedbits-1:0] tdc_data_codes;

	generate
		for (i=0; i < tdc_channels; i=i+1) begin : INPUTSTAGE	
			wire [bits-1:0] sample;
			carry_sampler_spartan6 #(.bits(bits),.resolution(resolution)) SAMPLER (
				.d(~tdc_channel[i]), 
				.q(sample),
				.CLK(CLK400));

			wire scaler;
			encode_96bit_pattern #(.encodedbits(encodedbits)) ENCODE (
				.edgechoice(1'b1), //historical leftover
				.d(sample),
				.enable(tdc_enable[i]),
				.CLK400(CLK400),
				.CLK200(CLK200),
				.code(tdc_data_codes[(i+1)*encodedbits-1:i*encodedbits]),
				.tdc_hit(tdc_hits[i]),
				.scaler_hit(scaler));

			//fake scaler hit for busyshift determination
			reg scaler_buffer;
			if (i==1) begin
				always@(posedge CLK200)
				begin
					if (fake_mode == 1'b1) begin
						scaler_buffer <= fake_data;
					end else begin
						scaler_buffer <= scaler;
					end
				end
			end else begin
				always@(posedge CLK200)
				begin
					scaler_buffer <= scaler;
				end
			end
			assign scaler_hits[i] = scaler_buffer;

		end
	endgenerate

	//unused channels
	assign tdc_hits[99:tdc_channels] = 'b0;










	//-----------------------------------------------------------------------------
	//-- Generate Trigger Outputs -------------------------------------------------
	//-----------------------------------------------------------------------------

	wire [95:0] trigger_hits;
	wire [23:0] trigger_first_or;

	//only use LVDS hits (data channels) for trigger output
	assign trigger_hits[95:0] = tdc_hits[96:1];

	generate
		for (i=0; i < 24; i=i+1) begin : TRIGGER_ORHITS
			assign trigger_first_or[i] = |trigger_hits[i*4+3:i*4]; 
		end
	endgenerate

	reg [23:0] trigger_out_0;
	reg [5:0] trigger_out_1;
	reg trigger_out_A;
	reg trigger_out_B;
	reg trigger_out_C;
	reg [2:0] trigger_choice_0;
	reg [2:0] trigger_choice_1;
	reg [1:0] trigger_out;

	always@(posedge CLK200)
	begin

		// generate trigger output signal
		trigger_out_0 <= trigger_first_or;
	
		trigger_out_1[0] <= |trigger_out_0[ 3: 0]; //A
		trigger_out_1[1] <= |trigger_out_0[ 7: 4]; //A
		trigger_out_1[2] <= |trigger_out_0[11: 8]; //B
		trigger_out_1[3] <= |trigger_out_0[15:12]; //B
		trigger_out_1[4] <= |trigger_out_0[19:16]; //C
		trigger_out_1[5] <= |trigger_out_0[23:20]; //C
		
		trigger_out_A <= |trigger_out_1[1:0];
		trigger_out_B <= |trigger_out_1[3:2];
		trigger_out_C <= |trigger_out_1[5:4];

		if (trigger_group_0[0] == 1'b1) trigger_choice_0[0] <= trigger_out_A; else  trigger_choice_0[0] <= 1'b0;
		if (trigger_group_0[1] == 1'b1) trigger_choice_0[1] <= trigger_out_B; else  trigger_choice_0[1] <= 1'b0;
		if (trigger_group_0[2] == 1'b1) trigger_choice_0[2] <= trigger_out_C; else  trigger_choice_0[2] <= 1'b0;

		if (trigger_group_1[0] == 1'b1) trigger_choice_1[0] <= trigger_out_A; else  trigger_choice_1[0] <= 1'b0;
		if (trigger_group_1[1] == 1'b1) trigger_choice_1[1] <= trigger_out_B; else  trigger_choice_1[1] <= 1'b0;
		if (trigger_group_1[2] == 1'b1) trigger_choice_1[2] <= trigger_out_C; else  trigger_choice_1[2] <= 1'b0;

		trigger_out[0] <= |trigger_choice_0;							
		trigger_out[1] <= |trigger_choice_1;							

	end










	//-----------------------------------------------------------------------------
	//-- jTDC ---------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	wire data_fifo_readrequest;
	wire event_fifo_readrequest;
	wire [31:0] data_fifo_value;
	wire [31:0] event_fifo_value;

	jTDC_core #(.tdc_channels(tdc_channels), .encodedbits(encodedbits), .fifocounts(fifocounts)) jTDC (
		.tdc_hits(tdc_hits), 
		.tdc_data_codes(tdc_data_codes), 
		.tdc_trigger_select(tdc_trigger_select), 
		.tdc_reset(tdc_reset), 
		.clock_limit(clock_limit), 
		.geoid(geoid), 
		.iBIT(iBIT), 
		.CLK200(CLK200),
		.CLKBUS(CLKBUS), 
		.event_fifo_readrequest(event_fifo_readrequest),
		.data_fifo_readrequest(data_fifo_readrequest), 
		.event_fifo_value(event_fifo_value), 
		.data_fifo_value(data_fifo_value) );

	readonly_register_with_readtrigger #(.myaddress(16'h8888)) EVENT_FIFO_READOUT (
		.databus(databus), 
		.addressbus(addressbus), 
		.readsignal(readsignal), 
		.readtrigger(event_fifo_readrequest), 
		.CLK(CLKBUS), 
		.registerbits(event_fifo_value));

	readonly_register_with_readtrigger #(.myaddress(16'h4444)) DATA_FIFO_READOUT (
		.databus(databus), 
		.addressbus(addressbus), 
		.readsignal(readsignal), 
		.readtrigger(data_fifo_readrequest), 
		.CLK(CLKBUS), 
		.registerbits(data_fifo_value));










	//-----------------------------------------------------------------------------
	//-- SCALER -------------------------------------------------------------------
	//-----------------------------------------------------------------------------

	generate
		
		if (scaler_channels > 0)
		begin

			//to reduce routing of the global addressbus, I implemented an internal
			//128 addr mux for the input scaler. They will use only one external addr,
			//each read request to the clock_counter_reg resets the scaler_addr and
			//each read request to the input_counter_reg increments the scaler_addr
			//furthermore, the input_counter_reg can be addressed by 128 consecutive
			//addresses (addressbus is masked), so the external readout can be performed
			//as usual, the input scalers just need to be read out in order
			wire scaler_readout_addr_reset;
			wire scaler_readout_addr_next;
			reg [6:0] scaler_readout_addr; 
			wire [31:0] scaler_readout_pipe_addr; 
			wor [31:0] muxed_counts;
	
			//busyshift
			wire [127:0] shifted_hits;
			BRAMSHIFT_512 #(.shift_bitsize(9),.width(4),.input_pipe_steps(1),.output_pipe_steps(1)) BRAM_BUSYSHIFT (
				.d({'b0,scaler_hits}), 
				.q(shifted_hits), 
				.CLK(CLK200), .shift(busyshift));

			//input counter
			for (i=0; i < 128; i=i+1) begin : INPUT_HITS_COUNTER

				if (i<scaler_channels && i<tdc_channels) begin
				
					//take sample[0] (re-inverted) for dutycycle measurement
					(* KEEP = "true" *) wire dutyline = ~INPUTSTAGE[i].sample[0];

					reg busycount;
					reg busycount_0;
					reg busycount_1;
					reg input_buffer;
					always@(posedge CLK200) begin
						input_buffer <= dutyline;
						busycount_0 <= shifted_hits[i] && ~busy;
						busycount_1 <= busycount_0;
						if (dutycycle == 1'b0) busycount <= busycount_1;
						else busycount <= input_buffer;
					end

					wire [31:0] input_counts;
					dsp_multioption_counter #(.clip_count(0)) INPUT_COUNTER (
						.countClock(CLK200), 
						.count(busycount),
						.reset(counter_reset),
						.countout(input_counts));

					wire [31:0] input_latched_counts;
					datalatch #(.latch_pipe_steps(1)) INPUT_COUNTER_DATALATCH  (
						.CLK(CLK200),
						.latch(counter_latch),
						.data(input_counts),
						.latched_data(input_latched_counts));

					//use the scaler_readout_addr to mux the correct counter to the readout register
					//since the source data is latched, the ucf constraint CROSSCLOCK is giving this mux 50ns to settle
					assign muxed_counts = (scaler_readout_addr == i) ? input_latched_counts : 32'b0;
					
				end 
				
			end


			//referenz clock counter (to be able to calculate rates)
			wire [31:0] pureclkcounts;
			dsp_multioption_counter #(.clip_count(0)) PURE_CLOCK_COUNTER (
				.countClock(CLK200), 
				.count(!busy), 
				.reset(counter_reset),  
				.countout(pureclkcounts));

			wire [31:0] clklatch;
			datalatch #(.latch_pipe_steps(1)) CLOCK_COUNTER_DATALATCH  (
				.CLK(CLK200),
				.latch(counter_latch),
				.data(pureclkcounts),
				.latched_data(clklatch));

			//read of this register resets the scaler_readout_addr
			readonly_register_with_readtrigger #(.myaddress(16'h0044)) CLOCK_COUNTER_READOUT ( 
				.databus(databus),
				.addressbus(addressbus),
				.readsignal(readsignal),
				.readtrigger(scaler_readout_addr_reset),
				.CLK(CLKBUS),
				.registerbits(clklatch)); 	
			
			//increment scaler_readout_addr on the negedge of next (=read) 
			//to keep the muxed value stable during read
			dsp_multioption_counter #(.clip_count(1),.clip_reset(1)) SCALER_READOUT_ADDR_INC (
				.countClock(CLKBUS), 
				.count(~scaler_readout_addr_next), 
				.reset(scaler_readout_addr_reset),  
				.countout(scaler_readout_pipe_addr));

			reg [31:0] muxed_counts_pipe;
			always@(posedge CLKBUS) begin
				muxed_counts_pipe <= muxed_counts;
				scaler_readout_addr <= scaler_readout_pipe_addr[6:0];
			end

			//each read of this register increments the scaler_readout_addr
			readonly_register_with_readtrigger #(.myaddress(16'h4000))  INPUT_COUNTER_READOUT ( 
				.databus(databus),
				.addressbus({addressbus[15:9],9'b0}), //from these 9 bits only 7 are usable
				.readsignal(readsignal),
				.readtrigger(scaler_readout_addr_next),
				.CLK(CLKBUS),
				.registerbits(muxed_counts_pipe));

		end
	endgenerate










	//-----------------------------------------------------------------------------
	//-- NIM Outputs --------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	wire [1:0] trigger_output;
	output_shaper TRIGGER_SHAPER_0 (
		.d(trigger_out[0]),
		.hightime(hightime),
		.deadtime(deadtime),
		.CLK(CLK200),
		.pulse(trigger_output[0]),
		.reset(output_reset));

	output_shaper TRIGGER_SHAPER_1 (
		.d(trigger_out[1]),
		.hightime(hightime),
		.deadtime(deadtime),
		.CLK(CLK200),
		.pulse(trigger_output[1]),
		.reset(output_reset));	

	assign NIM_OUT[0] = 0;
	assign NIM_OUT[1] = trigger_output[0];   //trigger out A
	assign NIM_OUT[2] = 0;   
	assign NIM_OUT[3] = trigger_output[1];   //trigger out B

	assign FPGA_SPARE = 0;
	assign USER_LED = 0;
	
endmodule
