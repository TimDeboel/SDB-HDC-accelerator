//-------------------------
// Copyright 2024
// binding operator module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Performs the binding step by shifting
//-------------------------
module binding_op #(
  parameter int unsigned HV_LENGTH = 2048
)(
  input logic                   clk_i,
  input logic                   rst_ni,
  input logic                   soft_reset,

  input logic [HV_LENGTH-1:0]   im_hv_in,
  // input logic [HV_LENGTH-1:0]   cim_hv_in,
  input logic                   start_op,
  // input logic                   segment_mode,  // Segment mode
  // input logic                   xor_binding_mode,
  input logic                   shift_binding_mode,
  input logic [5:0]             shift_amount,
  output logic [HV_LENGTH-1:0]  binding_hv_out,
  output logic                  out_ready
);

  // shift count reg
  logic [5:0] shift_counter;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      shift_counter <= 6'd0;
    end else begin
      if (!soft_reset) begin
        shift_counter <= 6'd0;
      end else if (shift_binding_mode) begin

        // if (start_op && !shift_binding_mode)
        //   shift_counter <= 6'd0;
        if (start_op)
          shift_counter <= shift_amount;
        else if (shift_counter > 0)
          shift_counter <= shift_counter - 1;
        else
          shift_counter <= 6'd0;

      end
    end
  end

  // Cyclic shifter
  logic [HV_LENGTH-1:0] sh_out;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      sh_out <= '0;
    end else begin
      if (shift_counter == shift_amount)
        sh_out <= {im_hv_in[0],im_hv_in[HV_LENGTH-1:1]};
      else if (shift_counter > 0)
        sh_out <= {sh_out[0],sh_out[HV_LENGTH-1:1]};  // Circular shift right
    end
  end

  always_comb begin
    if (!shift_binding_mode || shift_amount == 0) begin
      binding_hv_out = im_hv_in;
    end else begin
      binding_hv_out = sh_out;
    end
  end

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      out_ready <= 0;
    end else if (!shift_binding_mode && start_op) begin
      out_ready <= 1;
    end else if (shift_amount == 0 && start_op) begin
      out_ready <= 1;
    end else if (shift_counter == 1'b1) begin
      out_ready <= 1;
    end else begin
      out_ready <= 0;
    end
      
  end


endmodule
