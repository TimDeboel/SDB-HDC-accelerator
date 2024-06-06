//-------------------------
// Copyright 2023
// Simple Adder Testbench
// Made by: Danknight
// Description: 
// A testbench for the simple adder.
// It randomizes data
//-------------------------

module tb_adder;

	// Local parameters to be
	// fed into the module
	localparam int unsigned DataWidth = 8;
	localparam int unsigned MaxVal    = 2**DataWidth - 1;
	localparam int unsigned NumTests  = 10;

	// Wirings	
	logic                 clk_i;
	logic                 rst_ni;
	logic [DataWidth-1:0] a_data_i;
	logic [DataWidth-1:0] b_data_i;
	logic [DataWidth-1:0] c_data_o;

	// Always on clock at 20ns period
	// Clock level toggles every 10ns
	always begin #10; clk_i <= !clk_i; end

	// Instance of the simple adder module
	adder # (
		// Feed the local parameter
		.DataWidth( DataWidth )
	) i_adder (
		.clk_i 		( clk_i     ),
		.rst_ni 	( rst_ni    ),
		.a_data_i ( a_data_i  ),
		.b_data_i ( b_data_i  ),
		.c_data_o ( c_data_o  )
	);

	// Actual simulation run
	// This is where you set the stimuli
	initial begin

		// Initialize starting values
		// 1'b0 means 1 bit-wide set to 0
		// '0 means to set all the bits to 0
		clk_i = 1'b0;
		rst_ni = 1'b0;
		a_data_i = '0;
		b_data_i = '0;

		// Wait for a clock edge
		@(posedge clk_i);

		// Release the reset
		rst_ni = 1'b1;

		@(posedge clk_i);

		// Set random input values
		// Note that you can actually make this
		// Into tasks, google how to do it

		for (int i = 0; i < NumTests; i++) begin
			a_data_i = $urandom_range(MaxVal);
			b_data_i = $urandom_range(MaxVal);
			@(posedge clk_i);
		end

		#100ns;

	end



endmodule
