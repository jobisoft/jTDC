`timescale 1ps/1ps
//----------------------------------------------------------------------------
// "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
// "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
//----------------------------------------------------------------------------
// CLK_OUT1___100.000______0.000______50.0______183.967____177.296
// CLK_OUT2___200.000______0.000______50.0______161.043____177.296
// CLK_OUT3___400.000______0.000______50.0______140.976____177.296
//
//----------------------------------------------------------------------------
// "Input Clock   Freq (MHz)    Input Jitter (UI)"
//----------------------------------------------------------------------------
// __primary_________100.000___________0.0005
//----------------------------------------------------------------------------

module pll_vfb6_400 ( CLKIN,
                      CLK1,
                      CLK2,
                      CLK4 );

	input wire CLKIN;
	output wire CLK1;
	output wire CLK2;
	output wire CLK4;
	
	wire clkin1;
	wire clkout0;
	wire clkout1;
	wire clkout2;
	
	
  // Input buffering
  //------------------------------------
  IBUFG clkin1_buf
   (.O (clkin1),
    .I (CLKIN));

  wire        locked;
  wire        clkfbout;
  wire        clkfbout_buf;
  wire        clkout3;
  wire        clkout4;
  wire        clkout5;

  PLL_BASE
  #(.BANDWIDTH              ("HIGH"),
    .CLK_FEEDBACK           ("CLKFBOUT"),
    .COMPENSATION           ("SYSTEM_SYNCHRONOUS"),
    .DIVCLK_DIVIDE          (1),
    .CLKFBOUT_MULT          (8),
    .CLKFBOUT_PHASE         (0.000),
    .CLKOUT0_DIVIDE         (8),
    .CLKOUT0_PHASE          (0.000),
    .CLKOUT0_DUTY_CYCLE     (0.500),
    .CLKOUT1_DIVIDE         (4),
    .CLKOUT1_PHASE          (0.000),
    .CLKOUT1_DUTY_CYCLE     (0.500),
    .CLKOUT2_DIVIDE         (2),
    .CLKOUT2_PHASE          (0.000),
    .CLKOUT2_DUTY_CYCLE     (0.500),
    .CLKIN_PERIOD           (10.000),
    .REF_JITTER             (0.001))
  pll_base_inst (
    .CLKFBOUT              (clkfbout),
    .CLKOUT0               (clkout0),
    .CLKOUT1               (clkout1),
    .CLKOUT2               (clkout2),
    .CLKOUT3               (clkout3),
    .CLKOUT4               (clkout4),
    .CLKOUT5               (clkout5),
    .LOCKED                (locked),
    .RST                   (1'b0),
    .CLKFBIN               (clkfbout_buf),
    .CLKIN                 (clkin1));


  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clkfbout_buf),
    .I (clkfbout));

  BUFG clkout1_buf
   (.O   (CLK1),
    .I   (clkout0));


  BUFG clkout2_buf
   (.O   (CLK2),
    .I   (clkout1));

  BUFG clkout3_buf
   (.O   (CLK4),
    .I   (clkout2));



endmodule
