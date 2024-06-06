//-------------------------
// Copyright 2024
// Testbench for encode part of the sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Testbench before CSR implementation
//-------------------------

`timescale 1ns / 1ps
`define CLK_PERIOD 10
`define CLK_HALF 5
`define RESET_TIME 25

module tb_encode;

	// Local parameters to be
	// fed into the module
	localparam int unsigned HV_LENGTH = 1024;
	localparam int unsigned ACC1_SIZE = 3;
	localparam int unsigned AM_VECTOR_COUNT = 5;

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

  logic start;
  logic running;

  // In-out handshaking
  logic in_valid;   // New input ready to be read
  logic in_ready;  // Ready to receive new input
  logic input_done;

  // Input + Output
  logic [4:0] out;
  logic output_valid;
  logic [5:0] in_value;

  // TODO
  logic [HV_LENGTH-1:0] hv_temp_out;

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

	logic [AM_VECTOR_COUNT-1:0] ext_am_addr;
  logic ext_am_wen;
  logic ext_am_ren;
  logic [HV_LENGTH-1:0] ext_am_wdata;
  logic [HV_LENGTH-1:0] ext_am_rdata;

	logic [4:0] hw_out;


	// TODO
	logic [HV_LENGTH-1:0] hv_out;

	logic [HV_LENGTH-1:0] o_diff;

	// Instantiate the accelerator
	top_wrapper # (
		.HV_LENGTH(HV_LENGTH),
		.AM_VECTOR_COUNT(AM_VECTOR_COUNT)
	) i_top_wrapper (
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.start(start),
		.running(running),

		// In-out handshaking
		.in_valid(in_valid),   // New input ready to be read
		.in_ready(in_ready),  // Ready to receive new input
		.input_done(input_done),

		// Input + Output
		.out(out),
		.output_valid(output_valid),
		.in_value(in_value),

		.hv_temp_out(hv_temp_out),


		// Controls:
		// TODO replace these with CSR register + mapper
		.sliding_window_mode(sliding_window_mode),
		.signature_encoding_mode(signature_encoding_mode),
		.segment_mode(segment_mode),
		.xor_binding_mode(xor_binding_mode), // CIM + XOR binding enabled
		.shift_binding_mode_in(shift_binding_mode_in),
		.shift_amount_in(shift_amount),

		// Bundling
		.or_mode(or_mode),
		.acc1_mode(acc1_mode),
		.cdt_mode(cdt_mode),
		.acc2_mode(acc2_mode),
		.cdt_k_factor(cdt_k_factor),
		.thr1_val(thr1_val),
		.thr2_val(thr2_val),
		.window1_size(window1_size), // Amount of vectors to be bundled by OR array

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

		ext_am_addr = '0;
		ext_am_wen = 0;
		ext_am_ren = 0;
		ext_am_wdata = '0;

		score = 0;
		max_score = 0;

	end


	// Tasks
	task char_recognition_step;
		input [bits_char-1:0] char_data;
		begin
			shift_binding_mode_in <= 1'b1;
			// shift_amount <= 6'd1;
			or_mode <= 1'b1;
			cdt_mode <= 1'b1;
			cdt_k_factor <= 4'd1;
			window1_size <= 6'd35;

			// TODO put in for loop, with in_ready
			in_value <= 6'd0;
			shift_amount <= char_data[0];
			in_valid <= 1'b1;
			start <= 1'b1;
			#`CLK_PERIOD;
			start <= 1'b0;
			in_valid <= 1'b0;

			// TODO remove
			#`CLK_PERIOD;

			for(k = 1; k < bits_char; k = k + 1) begin
				wait (in_ready==1);
				in_value <= k;
				shift_amount <= char_data[k];
				in_valid <= 1'b1;
				#`CLK_PERIOD;
				in_valid <= 1'b0;
				// TODO remove
				#`CLK_PERIOD;
			end

			wait (output_valid==1);
			// hv_out <= hv_temp_out;
			hw_out <= out;
			#`CLK_PERIOD;
			shift_binding_mode_in <= 1'b0;
			or_mode <= 1'b0;
			cdt_mode <= 1'b0;

			#`CLK_PERIOD;
			#`CLK_PERIOD;
		end
	endtask


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

	task char_recognition;
		begin
			$display("char_recognition test");
			f = $fopen("../tb/char_data.txt", "r");
			h = $fopen("../tb/char_data_out.txt", "r");
			g = $fopen("../tb/tb_output_char.txt", "w");
				for(i = 0; i < rows_char; i = i + 1) begin
					for(j = 0; j < bits_char; j = j + 1) begin
						if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan failed");
						char_data[j] = value;
					end
					char_recognition_step(char_data);

					for (l = 4; l >= 0; l = l - 1) begin
						if ($fscanf(h, "%1b", value) == -1) $display("ERROR: fscan2 failed");
						o_correct_char[l] = value;
					end
					hv_diff(o_correct_char, hw_out);
					$fwrite(g, "Letter %0d: %b\n", i, hw_out);
					$fwrite(g, "Correct_: %b\n", o_correct_char);
					$fwrite(g, "Diff____: %b\n", o_diff);
					if (o_diff == 0) begin
						score += 1;
						max_score += 1;
						$fwrite(g, "Output OK\n");
					end else begin
						max_score += 1;
						$fwrite(g, "ERROR: output mismatch\n");
					end
				end
			$fwrite(g, "Char score: %0d / %0d tests successful\n", score, max_score);
			$display("Char score: %0d / %0d tests successful\n", score, max_score);

			$fclose(f);
			$fclose(g);
			$fclose(h);
		end
	endtask


	// Language recognition
	task lang_recognition_step;
		input [bits_lang-1:0] lang_data;
		begin
			sliding_window_mode <= 1'b1;
			signature_encoding_mode <= 1'b1;
			acc1_mode <= 1'b1;
			acc2_mode <= 1'b1;
			window1_size <= 6'd3;
			cdt_k_factor <= 4'd0;
			thr1_val <= 3'd2;
			thr2_val <= 7'd20; // 0.020 * 1024 = 20.48

			// TODO put in for loop with in_ready
			in_value <= lang_data;
			in_valid <= 1'b1;
			start <= 1'b1;
			#`CLK_PERIOD;
			start <= 1'b0;
			in_valid <= 1'b0;

			// TODO remove
			#`CLK_PERIOD;

			wait (in_ready==1);
			

			// wait (output_valid==1);
			// hv_out <= hv_temp_out;
			// #`CLK_PERIOD;

			// signature_encoding_mode <= 1'b0;
			// acc1_mode <= 1'b0;
			// acc2_mode <= 1'b0;
			// #`CLK_PERIOD;
			// #`CLK_PERIOD;
		end
	endtask

	task lang_recognition;
		begin
			$display("lang_recognition test");
			f = $fopen("../tb/lang_data.txt", "r");
			// h = $fopen("../tb/lang_after_thr1.txt", "r");
			h = $fopen("../tb/lang_data_encoded.txt", "r");
			g = $fopen("../tb/tb_output_lang.txt", "w");
			// for(i = 0; i < rows_lang; i = i + 1) begin
			while (!$feof(f)) begin // Read until end of file
				for(j = bits_lang-1; j >= 0; j = j - 1) begin
					if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan failed");
					lang_data[j] = value;
				end
				lang_recognition_step(lang_data);


			// 	Debug testing code, comment this
			// 	for (l = 1023; l >= 0; l = l - 1) begin
			// 		if ($fscanf(h, "%1b", value) == -1) $display("ERROR: fscan2 failed");
			// 		o_correct_hv[l] = value;
			// 	end
			// 	hv_diff(o_correct_hv, hv_temp_out);
			// 	$fwrite(g, "Window %0d: %b\n", i, hv_temp_out);
			// 	$fwrite(g, "Correct_: %b\n", o_correct_hv);
			// 	$fwrite(g, "Diff____: %b\n", o_diff);
			// 	if (o_diff == 0) begin
			// 		score += 1;
			// 		max_score += 1;
			// 		$fwrite(g, "Output OK\n");
			// 	end else begin
			// 		max_score += 1;
			// 		$fwrite(g, "ERROR: output mismatch\n");
			// 	end
			
			end

			input_done <= 1;
			wait (output_valid==1)
			#`CLK_PERIOD;
			hv_out <= hv_temp_out;
			hw_out <= out;
			sliding_window_mode <= 1'b0;
			signature_encoding_mode <= 1'b0;
			acc1_mode <= 1'b0;
			acc2_mode <= 1'b0;
			input_done <= 0;
			#`CLK_PERIOD;

			for (l = 1023; l >= 0; l = l - 1) begin
			if ($fscanf(h, "%1b", value) == -1) $display("ERROR: fscan2 failed");
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
			$fwrite(g, "Lang score: %0d / %0d tests successful\n", score, max_score);
			$display("Lang score: %0d / %0d tests successful\n", score, max_score);

			$fclose(f);
			$fclose(g);
			$fclose(h);
		end
	endtask


	// Mixed tests
	task mixed_testing_step;
		input [bits_lang-1:0] lang_data;
		begin
			// signature_encoding_mode <= 1'b1;
			// acc1_mode <= 1'b1;
			// acc2_mode <= 1'b1;
			// window1_size <= 6'd3;
			// or_mode <= 1'b0;
			// cdt_mode <= 1'b0;
			// cdt_k_factor <= 4'd1;
			// thr1_val <= 4'd2;
			// thr2_val <= 7'd200; // 0.020 * 1024 = 20.48

			// TODO put in for loop with in_ready
			in_value <= lang_data;
			in_valid <= 1'b1;
			start <= 1'b1;
			#`CLK_PERIOD;
			start <= 1'b0;
			in_valid <= 1'b0;

			// TODO remove
			#`CLK_PERIOD;

			wait (in_ready==1);
			

			// wait (output_valid==1);
			// hv_out <= hv_temp_out;
			// #`CLK_PERIOD;

			// signature_encoding_mode <= 1'b0;
			// acc1_mode <= 1'b0;
			// acc2_mode <= 1'b0;
			// #`CLK_PERIOD;
			// #`CLK_PERIOD;
		end
	endtask

	task mixed_testing;
		input int g;
		input int h;
		input sliding_window_mode_in;
		input signature_encoding_mode_in;
		input acc1_mode_in;
		input acc2_mode_in;
		input [5:0] window1_size_in;
		input or_mode_in;
		input cdt_mode_in;
		input	[3:0] cdt_k_factor_in;
		input [2:0] thr1_val_in;
		input [6:0] thr2_val_in;
		begin
			$display("Mixed test");

			sliding_window_mode <= sliding_window_mode_in;
			signature_encoding_mode <= signature_encoding_mode_in;
			acc1_mode <= acc1_mode_in;
			acc2_mode <= acc2_mode_in;
			window1_size <= window1_size_in;
			or_mode <= or_mode_in;
			cdt_mode <= cdt_mode_in;
			cdt_k_factor <= cdt_k_factor_in;
			thr1_val <= thr1_val_in;
			thr2_val <= thr2_val_in;
			#`CLK_PERIOD

			f = $fopen("../tb/mixed_data.txt", "r");
			// h = $fopen("../tb/mixed_data_encoded.txt", "r");
			// g = $fopen("../tb/tb_output_mixed.txt", "w");
			while (!$feof(f)) begin // Read until end of file
				for(j = bits_lang-1; j >= 0; j = j - 1) begin
					if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan failed");
					mixed_data[j] = value;
				end
				mixed_testing_step(mixed_data);
			
			end

			input_done <= 1;
			wait (output_valid==1)
			#`CLK_PERIOD;
			hv_out <= hv_temp_out;
			hw_out <= out;
			sliding_window_mode <= 1'b0;
			signature_encoding_mode <= 1'b0;
			acc1_mode <= 1'b0;
			acc2_mode <= 1'b0;
			or_mode <= 1'b0;
			cdt_mode <= 1'b0;
			input_done <= 0;
			#`CLK_PERIOD;

			for (l = 1023; l >= 0; l = l - 1) begin
			if ($fscanf(h, "%1b", value) == -1) $display("ERROR: fscan2 failed");
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

			$display("Mixed out: %b\n", hw_out);
			$fwrite(g, "Mixed score: %0d / %0d tests successful\n", score, max_score);
			$display("Mixed score: %0d / %0d tests successful\n", score, max_score);

			$fclose(f);
			// $fclose(g);
			// $fclose(h);
		end
	endtask


	task load_am;
		input [1:0] load_sel;
		begin
			$display("Loading Associative Memory");
			ext_am_wen <= 1'b1;
			if (load_sel == 2'd0)
				f = $fopen("../tb/char_am.txt", "r");
			else if (load_sel == 2'd1)
				f = $fopen("../tb/lang_am.txt", "r");

			load_line = 0;
			while (!$feof(f)) begin // Read until end of file

				for(j = HV_LENGTH-1; j >= 0; j = j - 1) begin
					if ($fscanf(f, "%1b", value) == -1) $display("ERROR: fscan load failed");
					am_line[j] = value;
				end
				
				ext_am_addr <= load_line;
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
			rst_ni <= 0;
			#`CLK_PERIOD;
			rst_ni <= 1;
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

		load_am(2'd0);
		char_recognition();

		reset();
		load_am(2'd1);

		lang_recognition();

		#100ns;

		h = $fopen("../tb/mixed_data_encoded.txt", "r");
		g = $fopen("../tb/tb_output_mixed.txt", "w");
		
		reset();
		// Lang with other input and thr
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b1),
			.signature_encoding_mode_in(1'b1),
			.acc1_mode_in(1'b1),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd3),
			.or_mode_in(1'b0),
			.cdt_mode_in(1'b0),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd100)
		);

		reset();
		// Max sliding window size
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b1),
			.signature_encoding_mode_in(1'b1),
			.acc1_mode_in(1'b1),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd12),
			.or_mode_in(1'b0),
			.cdt_mode_in(1'b0),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd100)
		);

		reset();
		// Sliding window without signature encoding
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b1),
			.signature_encoding_mode_in(1'b0),
			.acc1_mode_in(1'b1),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd4),
			.or_mode_in(1'b0),
			.cdt_mode_in(1'b0),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd20)
		);

		reset();
		// Other window and or_mode instead of acc1
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b1),
			.signature_encoding_mode_in(1'b1),
			.acc1_mode_in(1'b0),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd2),
			.or_mode_in(1'b1),
			.cdt_mode_in(1'b0),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd100)
		);

		reset();
		// or_mode and cdt_mode followed by acc2
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b1),
			.signature_encoding_mode_in(1'b1),
			.acc1_mode_in(1'b0),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd2),
			.or_mode_in(1'b1),
			.cdt_mode_in(1'b1),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd50)
		);

		reset();
		// Only cdt, no bundling in stage1
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b0),
			.signature_encoding_mode_in(1'b0),
			.acc1_mode_in(1'b0),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd1),
			.or_mode_in(1'b0),
			.cdt_mode_in(1'b1),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd50)
		);

		reset();
		// Only stage 2 bundling, no bundling in stage1
		mixed_testing(
			.g(g),
			.h(h),
			.sliding_window_mode_in(1'b0),
			.signature_encoding_mode_in(1'b0),
			.acc1_mode_in(1'b0),
			.acc2_mode_in(1'b1),
			.window1_size_in(6'd1),
			.or_mode_in(1'b0),
			.cdt_mode_in(1'b0),
			.cdt_k_factor_in(4'd1),
			.thr1_val_in(3'd2),
			.thr2_val_in(7'd100)
		);
		

		$fclose(g);
		$fclose(h);


		#100ns;
		$stop;
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
