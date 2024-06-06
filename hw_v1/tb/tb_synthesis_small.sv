//-------------------------
// Copyright 2024
// Testbench for the synthesis
// Made by: Tim Deboel
// Description: 
//-------------------------

`timescale 1ns / 1ps
`define CLK_PERIOD 10
`define CLK_HALF 5
`define RESET_TIME 25

module tb_synthesis;

	// Local parameters to be
	// fed into the module
	localparam int unsigned HV_LENGTH = 2048;
	localparam int unsigned CSR_WIDTH = 32;
  localparam int unsigned CSR_ADDR_WIDTH = 32;
	localparam int unsigned ACC1_SIZE = 3;
	localparam int unsigned AM_ADDR_WIDTH = 13;

	// Inputs from file
	parameter bits_char = 35;
	parameter rows_char = 26;
	parameter bits_lang = 6;
	integer f, g, i, j, k, h, l, score, max_score, load_line;
	bit value;

	logic [HV_LENGTH-1:0] am_line;
	logic [bits_char-1:0] char_data;
	logic [bits_lang-1:0] lang_data;
	logic [bits_lang-1:0] mixed_data;
	logic [HV_LENGTH-1:0] o_correct_hv;
	logic [4:0] o_correct_char;


	// Wirings	
	logic clk_i;
  logic rst_ni;

	// CSR
	logic [CSR_ADDR_WIDTH-1:0] csr_addr_i;
  logic [CSR_WIDTH-1:0]      csr_wr_data_i;
  logic                      csr_wr_en_i;
  logic                      csr_req_valid_i;
  logic                      csr_req_ready_o;
  logic [CSR_WIDTH-1:0]      csr_rd_data_o;
  logic                      csr_rsp_valid_o;
  logic                      csr_rsp_ready_i;

	// AM access from DMA
	logic [47:0] ext_am_addr;
  logic ext_am_wen;
  logic ext_am_ren;
  logic [HV_LENGTH-1:0] ext_am_wdata;
  logic [HV_LENGTH-1:0] ext_am_rdata;

	logic [4:0] hw_out;

	logic [HV_LENGTH-1:0] hv_out;
	logic [HV_LENGTH-1:0] o_diff;

	// Input + Output
	logic in_valid;   // New input ready to be read
  logic in_ready;  // Ready to receive new input
  logic input_done;
  logic [4:0] out;
  logic output_valid;
  logic [5:0] in_value;
	logic start;

	// Controls:
  // TODO replace these with CSR register + mapper
	logic sliding_window_mode;
	logic signature_encoding_mode;
  logic segment_mode;
  logic xor_binding_mode; // CIM + XOR binding enabled
  logic shift_binding_mode_in;
  logic [5:0] shift_amount;

  // Bundling
  logic or_mode;
  logic acc1_mode;
  logic cdt_mode;
  logic acc2_mode;
  logic [3:0] cdt_k_factor;
  logic [ACC1_SIZE-1:0] thr1_val;
  logic [6:0] thr2_val;
  logic [5:0] window1_size;


	// Instantiate the accelerator
	top_wrapper # (
		.HV_LENGTH(HV_LENGTH),
		.CSR_WIDTH(CSR_WIDTH),
    .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH),
		.AM_ADDR_WIDTH(AM_ADDR_WIDTH)
	) top_wrapper_i (
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		
		.csr_addr_i(csr_addr_i),
    .csr_wr_data_i(csr_wr_data_i),
    .csr_wr_en_i(csr_wr_en_i),
    .csr_req_valid_i(csr_req_valid_i),
    .csr_req_ready_o(csr_req_ready_o),
    .csr_rd_data_o(csr_rd_data_o),
    .csr_rsp_valid_o(csr_rsp_valid_o),
    .csr_rsp_ready_i(csr_rsp_ready_i),

		.ext_am_addr(ext_am_addr),
    .ext_am_wen(ext_am_wen),
    .ext_am_ren(ext_am_ren),
    .ext_am_wdata(ext_am_wdata),
    .ext_am_rdata(ext_am_rdata)
	);

	// Generate Clock
	initial begin
		clk_i = 0;
		forever #`CLK_HALF clk_i = ~clk_i;
	end

	initial begin

		// Starting values
		// '0 means set all bits_char to 0
		clk_i = 1'b0;
		rst_ni = 1'b0;

		csr_addr_i = '0;
		csr_wr_data_i = '0;
		csr_wr_en_i = 0;
		csr_req_valid_i = 0;
		csr_rsp_ready_i = 0;

		ext_am_addr = '0;
		ext_am_wen = 0;
		ext_am_ren = 0;
		ext_am_wdata = '0;

		score = 0;
		max_score = 0;



		start = 1'b0;
		in_valid = 1'b0;
		input_done = 1'b0;
		in_value = '0;

		sliding_window_mode = 1'b0;
		signature_encoding_mode = 1'b0;
		segment_mode = 1'b0;
		xor_binding_mode = 1'b0;
		shift_binding_mode_in = 1'b0;
		shift_amount = '0;

		or_mode = 1'b0;
		acc1_mode = 1'b0;
		cdt_mode = 1'b0;
		acc2_mode = 1'b0;
		cdt_k_factor = '0;
		thr1_val = '0;
		thr2_val = '0;
		window1_size = '0;

	end


	// Tasks
	task hv_diff;
		input [HV_LENGTH-1:0] hv_a;
		input [HV_LENGTH-1:0] hv_b;
		begin
			assign o_diff = hv_a ^ hv_b;
			$display("o_diff = %b", o_diff);
			if (o_diff == 0)
				$display("Output OK");
			else 
				$display("Output mismatch");
		end
	endtask
	
	// Language recognition
	task lang_recognition_step;
		input [bits_lang-1:0] lang_data;
		begin

			csr_addr_i 						<= 1; // program input
			csr_wr_data_i[0] 			<= 1;	// in_valid
			csr_wr_data_i[6:1] 		<= lang_data;	// in_value
			csr_wr_data_i[31:7] 	<= 0;
			csr_wr_en_i <= 1;
			csr_req_valid_i <= 1;
			#`CLK_PERIOD;
			csr_wr_data_i[0] <= 0;	// in_valid
			// TODO remove
			#`CLK_PERIOD;

			wait (csr_req_ready_o==1);
			
		end
	endtask

	task lang_recognition;
		begin
			$display("lang_recognition test");

			// CSR settings
			csr_wr_en_i 					<= 1;
			csr_req_valid_i 			<= 1;

			csr_addr_i 						<= 3; // program binding
			csr_wr_data_i[0] 			<= 1; // sliding_window_mode
			csr_wr_data_i[1] 			<= 1; // signature_encoding_mode
			// csr_wr_data_i[3] 			<= 0; // xor_binding_mode
			csr_wr_data_i[2] 			<= 0;	// shift_binding_mode
			csr_wr_data_i[31:3] 	<= 0;
			#`CLK_PERIOD;
			csr_addr_i 						<= 4; // program bundling
			csr_wr_data_i[0] 			<= 1;	// acc1_mode
			csr_wr_data_i[1] 			<= 0;	// cdt_mode
			csr_wr_data_i[2] 			<= 1;	// acc2_mode
			csr_wr_data_i[8:3] 		<= 3; // window1_size
			csr_wr_data_i[12:9] 	<= 1; // cdt_k_factor
			csr_wr_data_i[15:13] 	<= 2;	// thr1
			csr_wr_data_i[22:16] 	<= 8; // thr2 		0.020 * 1024 = 20.48	0.008 * 1024 = 8.192
			csr_wr_data_i[23] 		<= 0;	// or_mode
			csr_wr_data_i[24] 		<= 0;	// write to AM
			csr_wr_data_i[31:25] 	<= 0;
			#`CLK_PERIOD;
			csr_addr_i 						<= 5; // AM base settings
			csr_wr_data_i					<= 1*256; // AM base address
			#`CLK_PERIOD;
			csr_addr_i 						<= 6; // AM max settings
			csr_wr_data_i 				<= 7*256; // AM max address
			#`CLK_PERIOD;
			csr_addr_i 						<= 0; // start accelerator
			csr_wr_data_i[0] 			<= 1;
			csr_wr_data_i[31:1] 	<= 0;
			#`CLK_PERIOD;
			csr_wr_en_i 					<= 0;
			csr_req_valid_i 			<= 0;
			#`CLK_PERIOD;

			f = $fopen("../tb/data/lang_data.txt", "r");
			// h = $fopen("../tb/lang_after_thr1.txt", "r");
			h = $fopen("../tb/data/lang_encoded_2k.txt", "r");
			g = $fopen("../tb/tb_output_lang.txt", "w");
			// for(i = 0; i < rows_lang; i = i + 1) begin
			while (!$feof(f)) begin // Read until end of file
				for(j = bits_lang-1; j >= 0; j = j - 1) begin
					if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan lang_data failed");
					lang_data[j] = value;
				end
				lang_recognition_step(lang_data);
			
			end

			csr_addr_i 						<= 1; // program input
			csr_wr_data_i[0] 			<= 0;	// in_valid
			csr_wr_data_i[6:1] 		<= 0;	// in_value
			csr_wr_data_i[12:7] 	<= 0;	// shift_amount
			csr_wr_data_i[13]			<= 1; // input_done
			csr_wr_data_i[31:14]	<= 0;
			#`CLK_PERIOD;
			csr_req_valid_i <= 0;
			csr_wr_en_i <= 0;	// disable write
			csr_addr_i <= 2; // status addr
			#`CLK_PERIOD;
			wait (csr_rd_data_o[2]==1);	// output valid
			hw_out <= csr_rd_data_o[7:3];
			hv_out <= top_wrapper_i.top_system_i.encoded_hv;
			#`CLK_PERIOD;

			// Verify outputs
			for (l = HV_LENGTH-1; l >= 0; l = l - 1) begin
			if ($fscanf(h, "%1b", value) == -1) $display("ERROR: fscan correct_lang failed");
				o_correct_hv[l] = value;
			end
			hv_diff(o_correct_hv, hv_out);
			$fwrite(g, "Encoded: %b\n", hv_out);
			$fwrite(g, "Correct: %b\n", o_correct_hv);
			$fwrite(g, "Diff___: %b\n", o_diff);
			if (o_diff == 0) begin
				score += 1;
				max_score += 1;
				$fwrite(g, "Output OK\n");
			end else begin
				max_score += 1;
				$fwrite(g, "ERROR: output mismatch\n");
			end

			$display("Lang out: %b\n", hw_out);
			$fwrite(g, "Lang out: %b\n", hw_out);
			$fwrite(g, "Lang score: %0d / %0d tests successful\n", score, max_score);
			$display("Lang score: %0d / %0d tests successful\n", score, max_score);

			$fclose(f);
			$fclose(g);
			$fclose(h);
		end
	endtask


	task load_am;
		input [1:0] load_sel;
		begin
			$display("Loading Associative Memory");
			ext_am_wen <= 1'b1;
			if (load_sel == 2'd0)
				f = $fopen("../tb/data/char_am_2k.txt", "r");
			else if (load_sel == 2'd1)
				f = $fopen("../tb/data/lang_am_2k.txt", "r");

			load_line = 0;
			while (!$feof(f)) begin // Read until end of file

				for(j = HV_LENGTH-1; j >= 0; j = j - 1) begin
					if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan load failed");
					am_line[j] = value;
				end
				
				if (load_sel == 2'd0)
					ext_am_addr <= {load_line,{8{1'b0}}};
				else if (load_sel == 2'd1)
					ext_am_addr <= {load_line+1,{8{1'b0}}};	// base address of 256 for lang recognition

				ext_am_wdata <= am_line; // TODO check end of line read okay (\n?)
				#`CLK_PERIOD;

				load_line += 1;
				// Test delay between inputs
				// #`CLK_PERIOD;
				// #`CLK_PERIOD;
				// #`CLK_PERIOD;

			end
			
			ext_am_wen <= 1'b0;
			#`CLK_PERIOD;
		end
	endtask

	task reset;
		begin
			csr_wr_en_i 					<= 1;
			csr_req_valid_i 			<= 1;

			csr_addr_i 						<= 7; // reset address
			csr_wr_data_i[0]			<= 1; // reset enable
			csr_wr_data_i[31:1] 	<= 0;
			#`CLK_PERIOD;
			csr_wr_en_i 					<= 0;
			csr_req_valid_i 			<= 0;
			#`CLK_PERIOD;
		end
	endtask


	// Tests
	initial begin
		#`RESET_TIME
		rst_ni <= 0;
		#`CLK_PERIOD;
		rst_ni <= 1;
		#`CLK_PERIOD;

		load_am(2'd1);
		#`CLK_PERIOD;
		#`CLK_PERIOD;

		// Specify the name of the VCD file
		// Dump waveforms for synthesis
    $fsdbDumpfile("output.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpon;


		lang_recognition();

		#`CLK_PERIOD;

		$fsdbDumpoff;

		$finish;

		// Set random input values
		// Note that you can actually make this
		// Into tasks, google how to do it
		// for (int i = 0; i < NumTests; i++) begin
		// 	a_data_i = $urandom_range(MaxVal);
		// 	b_data_i = $urandom_range(MaxVal);
		// 	@(posedge clk_i);
		// end
		// #100ns;

	end



endmodule
