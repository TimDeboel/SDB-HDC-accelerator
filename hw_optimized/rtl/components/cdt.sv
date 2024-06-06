//-------------------------
// Copyright 2024
// CDT module
// Made by: Tim Deboel
// Description: 
// Implements the Context-Dependent Thinning operation
// Single cycle execution
//-------------------------
module cdt #(
  parameter int unsigned HV_LENGTH
) (
  input logic clk_i,
  input logic rst_ni,

  input logic cdt_mode,
  input logic acc1_mode,
  input logic in_counter_prev_zero,
  input logic [3:0] cdt_k_factor,

  input logic [HV_LENGTH-1:0] cdt_in,

  output logic [HV_LENGTH-1:0] cdt_out
);
  
  always_comb begin
    if (cdt_mode) begin
      if (in_counter_prev_zero || !acc1_mode) begin
      case(cdt_k_factor)
          2'd1: cdt_out = ( cdt_in & {cdt_in[0], cdt_in[HV_LENGTH-1:1]} );
          2'd2: cdt_out = ( cdt_in & ( {cdt_in[0], cdt_in[HV_LENGTH-1:1]} | {cdt_in[1:0], cdt_in[HV_LENGTH-1:2]} ) );
          2'd3: cdt_out = ( cdt_in & ( {cdt_in[0], cdt_in[HV_LENGTH-1:1]} | {cdt_in[1:0], cdt_in[HV_LENGTH-1:2]} | {cdt_in[2:0], cdt_in[HV_LENGTH-1:3]} ) );
          default: cdt_out = cdt_in;
      endcase
      end

    end
  end

endmodule