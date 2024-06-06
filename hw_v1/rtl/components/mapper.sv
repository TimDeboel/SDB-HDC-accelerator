//-------------------------
// Copyright 2024
// mapping module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Maps the CSR inputs to the correct signals for signature encoding etc.
//-------------------------
module mapper #(
  parameter int unsigned HV_LENGTH = 2048,
  parameter int unsigned MAX_WINDOW1_SIZE = 12,
  parameter int unsigned AM_VECTOR_COUNT = 5
) (
  input logic clk_i,
  input logic rst_ni,
  input logic soft_reset,

  input logic in_valid,
  input logic [5:0] in_value,

  input logic binding_done,
  output logic [5:0] in_value_mapper,
  output logic in_valid_mapper, // Input ready to be read
  output logic in_ready_mapper, // New input ready to be sent
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
            // in_value_a <= in_value;
            // in_value_b <= in_value_a;
            // in_value_c <= in_value_b;
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

  // XOR the other 3 vectors from the size 4 window and shift this amount
  logic [5:0] win_counter;
  logic sig_in_valid;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      win_counter <= 6'd0;
      sig_in_valid <= 0;
      in_ready_mapper <= 0;
    end else begin
      if (!soft_reset || !sliding_window_mode) begin
        win_counter <= 6'd0;
        sig_in_valid <= 0;
        in_ready_mapper <= binding_done;
      end else begin

        if (in_valid && (win_counter == window1_size || win_counter == 0)) begin
          win_counter <= 6'd0;
          sig_in_valid <= 1;
          in_ready_mapper <= 0;
        end else if ((win_counter < window1_size) && binding_done) begin
          win_counter <= win_counter + 1;
          sig_in_valid <= 1;
          in_ready_mapper <= 0;
        end else if (win_counter == window1_size) begin
          sig_in_valid <= 0;
          in_ready_mapper <= binding_done;
        end else begin
          sig_in_valid <= 0;
          in_ready_mapper <= 0;
        end

      end
    end
  end

  always_comb begin
    in_valid_mapper = (sliding_window_mode) ? sig_in_valid : in_valid;
    
    if (sliding_window_mode) begin
      im_en = sig_in_valid && (im_en_values[win_counter] == 1);
      im_zero = sig_in_valid && (im_en_values[win_counter] == 0);
    end else begin
      im_en = in_valid;
    end
  end
   

  // always_comb begin
  //   if (sliding_window_mode) begin
  //     case (win_counter)
  //       6'd0: begin
  //         in_value_mapper = in_value_queue[0];
  //         shift_amount = 6'd0 + (in_value_b ^ in_value_c ^ in_value_d);
  //       end
  //       6'd1: begin
  //         in_value_mapper = in_value_b;
  //         shift_amount = 6'd1 + (in_value_a ^ in_value_c ^ in_value_d);
  //       end
  //       6'd2: begin
  //         in_value_mapper = in_value_c;
  //         shift_amount = 6'd2 + (in_value_a ^ in_value_b ^ in_value_d);
  //       end
  //       6'd3: begin
  //         in_value_mapper = in_value_d;
  //         shift_amount = 6'd3 + (in_value_a ^ in_value_b ^ in_value_c);
  //       end

  //       default: begin
  //         in_value_mapper = in_value_a;
  //         shift_amount = 6'd1;
  //       end
  //     endcase
  //   end else begin
  //     in_value_mapper = in_value;
  //     shift_amount = shift_amount_in;
  //   end
  // end

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
