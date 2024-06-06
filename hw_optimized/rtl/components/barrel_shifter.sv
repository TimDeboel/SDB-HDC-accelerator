//-------------------------
// Copyright 2024
// Barrel shifter / rotator
// Made by: Tim Deboel
// Description: 
// Multi-stage fully-combinational rotator
// Can rotate 0-63 times in one cycle
//-------------------------
module barrel_shifter #(
  parameter int unsigned HV_LENGTH,
  parameter int unsigned SHIFT_SIZE = 6
) (
  input  logic [HV_LENGTH-1:0]  input_data,
  input  logic [SHIFT_SIZE-1:0] shift_amount,
  output logic [HV_LENGTH-1:0]  output_data
);

  logic [HV_LENGTH-1:0] s0,s1,s2,s3,s4,s5;
  always_comb begin
    s0 = shift_amount[0] ? {input_data[0],  input_data[HV_LENGTH-1:1]}  : input_data;
    s1 = shift_amount[1] ? {s0[1:0],        s0[HV_LENGTH-1:2]}          : s0;
    s2 = shift_amount[2] ? {s1[3:0],        s1[HV_LENGTH-1:4]}          : s1;
    s3 = shift_amount[3] ? {s2[7:0],        s2[HV_LENGTH-1:8]}          : s2;
    s4 = shift_amount[4] ? {s3[15:0],       s3[HV_LENGTH-1:16]}         : s3;
    s5 = shift_amount[5] ? {s4[31:0],       s4[HV_LENGTH-1:32]}         : s4;

    output_data = s5;
  end

endmodule