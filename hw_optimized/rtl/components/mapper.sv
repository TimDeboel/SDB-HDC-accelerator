//-------------------------
// Copyright 2024
// Mapping module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Provides the signature encoding functionality for sliding windows
// and controls the ready signal to request new inputs
//-------------------------
module mapper #(
  parameter int unsigned HV_LENGTH = 1024,
  parameter int unsigned MAX_WINDOW1_SIZE = 12,
  parameter int unsigned AM_VECTOR_COUNT = 5
) (
  input logic clk_i,
  input logic rst_ni,
  input logic soft_reset,

  input logic in_valid,
  input logic [5:0] in_value,
  input logic running,

  input logic binding_done,
  output logic [5:0] in_value_mapper,
  output logic in_valid_mapper, // Input ready to be read
  output logic in_ready_internal, // New input ready to be sent
  output logic im_en,
  output logic im_zero,

  input logic sliding_window_mode,
  input logic signature_encoding_mode,
  input logic [5:0] shift_amount_in,
  input logic [5:0] window1_size,

  output logic [5:0] shift_amount

);
  
  // max sliding window size = 12
  // Save the 12 letters from the input window in registers
  logic [5:0] in_value_queue [MAX_WINDOW1_SIZE-1:0];
  logic [MAX_WINDOW1_SIZE-1:0] im_en_values;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      in_value_queue <= '{default:'0};
      im_en_values <= '0;
    end else begin

      if (!soft_reset) begin
        im_en_values <= '0;
        in_value_queue <= '{default:'0};
      end else begin

        if (sliding_window_mode) begin

          if (in_valid) begin
            in_value_queue[0] <= in_value;
            for (int i=0; i<($size(in_value_queue)-1); i++) begin
              if (i < window1_size)
                in_value_queue[i+1] <= in_value_queue[i];
            end
            
            // Propagate im_en signal
            im_en_values[0] <= 1'b1;
            for (int i=1; i<$size(im_en_values); i++)
              im_en_values[i] <= im_en_values[i-1];
          end

        end else begin
          im_en_values <= '0;
          in_value_queue <= '{default:'0};
        end

      end

    end
  end

  // window counter logic (determines reading position in sliding window)
  logic [5:0] win_counter;
  logic sig_in_valid;
  logic in_ready_mapper;
  logic counter_active;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      win_counter <= 6'd0;
      sig_in_valid <= 0;
      in_ready_mapper <= 0;
      counter_active <= 0;
    end else begin
      if (!soft_reset) begin
        win_counter <= 6'd0;
        sig_in_valid <= 0;
        in_ready_mapper <= 0;
        counter_active <= 0;
      end else if (!sliding_window_mode) begin
        win_counter <= 6'd0;
        sig_in_valid <= 0;
        in_ready_mapper <= 1; // Can receive a new input on each cycle
        counter_active <= 0;
      end else if (running) begin
        if (window1_size == 1) begin
            if (in_valid) begin
              win_counter <= 0;
              sig_in_valid <= 1;
              in_ready_mapper <= 1;
              counter_active <= 1;
            end else if (counter_active) begin
              win_counter <= 1;
              sig_in_valid <= 1;
              in_ready_mapper <= 0;
              counter_active <= 0;
            end else begin
              win_counter <= 0;
              sig_in_valid <= 0;
              in_ready_mapper <= 0;
          end
          
        end else begin
          if (in_valid && (win_counter == 0 || win_counter == window1_size)) begin
            win_counter <= 6'd0;
            sig_in_valid <= 1;
            in_ready_mapper <= 0;
            counter_active <= 1;
          end else if (counter_active && (win_counter == (window1_size-2)) ) begin
            win_counter <= win_counter + 1;
            sig_in_valid <= 1;
            in_ready_mapper <= 1;
          end else if (counter_active && (win_counter < window1_size)) begin
            win_counter <= win_counter + 1;
            sig_in_valid <= 1;
            in_ready_mapper <= 0;
          end else if (win_counter == window1_size) begin
            sig_in_valid <= 0;
            in_ready_mapper <= 0;
            counter_active <= 0;
            win_counter <= 6'd0;
          end else begin
            sig_in_valid <= 0;
            in_ready_mapper <= 0;
          end
        end

      end
    end
  end

  // always_comb begin
  //   if (sliding_window_mode && win_counter == 0 && !in_valid) begin
  //     in_ready_internal = 1;
  //   end else begin
  //     in_ready_internal = in_ready_mapper;
  //   end
  // end
  assign in_ready_internal = in_ready_mapper;

  always_comb begin
    in_valid_mapper = (sliding_window_mode) ? sig_in_valid : in_valid;
    
    if (sliding_window_mode) begin
      im_en = sig_in_valid && (im_en_values[win_counter] == 1);
      im_zero = sig_in_valid && (im_en_values[win_counter] == 0);
    end else begin
      im_en = in_valid;
      im_zero = 0;
    end
  end

  logic [5:0] xor_tot;
  logic [5:0] xor_added;
  always_comb begin

    if (sliding_window_mode) begin

      if (signature_encoding_mode)
        xor_tot = in_value_queue[0] ^ in_value_queue[1] ^ in_value_queue[2] ^ in_value_queue[3] ^ in_value_queue[4] ^ in_value_queue[5] ^ in_value_queue[6] ^ in_value_queue[7] ^ in_value_queue[8] ^ in_value_queue[9] ^ in_value_queue[10] ^ in_value_queue[11];
      else
        xor_tot = 0;

      for (int k=0; k<(MAX_WINDOW1_SIZE); k++) begin
        if (win_counter == k) begin

          in_value_mapper = in_value_queue[k];
          if (signature_encoding_mode)
            xor_added = xor_tot ^ in_value_queue[k];
          else
            xor_added = '0;
          shift_amount = win_counter + xor_added;

        end
      end

    end else begin
      in_value_mapper = in_value;
      shift_amount = shift_amount_in;
      xor_tot = '0;
    end
  end

endmodule
