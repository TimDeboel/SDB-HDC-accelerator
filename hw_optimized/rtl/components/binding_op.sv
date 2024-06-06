//-------------------------
// Copyright 2024
// Binding operator module
// Made by: Tim Deboel
// Description: 
// Performs the binding step by permutation
//-------------------------
module binding_op #(
  parameter int unsigned HV_LENGTH = 1024
)(
  input logic                   clk_i,
  input logic                   rst_ni,

  input logic   [HV_LENGTH-1:0] im_hv_in,
  input logic                   start_op,

  input logic                   shift_binding_mode,
  input logic   [5:0]           shift_amount,
  output logic  [HV_LENGTH-1:0] binding_hv_out,
  output logic                  out_ready
);

  // Barrel shifter
  logic [HV_LENGTH-1:0] permuted_hv;
  barrel_shifter #(
    .HV_LENGTH(HV_LENGTH),
    .SHIFT_SIZE(6)
  ) instance_name (
    .input_data(im_hv_in),
    .shift_amount(shift_binding_mode ? shift_amount : 6'd0),
    .output_data(permuted_hv)
  );
  
  // Shift register
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      binding_hv_out <= '0;
    end else begin
      binding_hv_out <= permuted_hv;
    end
  end

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      out_ready <= 0;
    end else begin
      out_ready <= start_op;
    end
  end


endmodule
