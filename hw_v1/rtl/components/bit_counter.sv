//-------------------------
// Copyright 2024
// Bit counter for the similarity score
// Made by: Tim Deboel
// Description: 
// Single cycle bit counter
//-------------------------
module bit_counter #(
  parameter int unsigned N = 2048,
  parameter int unsigned AM_ADDR_WIDTH = 13
) (
  input logic clk_i,
  input logic rst_ni,
  input logic in_valid,
  input logic [N-1:0] input_data,
  output logic [$clog2(N+1)-1:0] bit_count_out,
  output logic out_valid,
  input logic [AM_ADDR_WIDTH-1:0] in_addr,
  output logic [AM_ADDR_WIDTH-1:0] out_addr
);

  // logic [$clog2(N+1)-1:0] bit_count;
  logic [N-1:0] input_reg;

  logic [$clog2(N+1)-1:0] bit_count_out1,bit_count_out2,bit_count_out3,bit_count_out4;

  always_comb begin
    // bit_count = '0;
    bit_count_out1 = '0;
    bit_count_out2 = '0;
    bit_count_out3 = '0;
    bit_count_out4 = '0;
    if (in_valid) begin
      for (integer i = 0; i < N/4; i = i + 1) begin
        bit_count_out1 = bit_count_out1 + {{($clog2(N+1)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N/4; i < N/2; i = i + 1) begin
        bit_count_out2 = bit_count_out2 + {{($clog2(N+1)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N/2; i < N*3/4; i = i + 1) begin
        bit_count_out3 = bit_count_out3 + {{($clog2(N+1)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*3/4; i < N; i = i + 1) begin
        bit_count_out4 = bit_count_out4 + {{($clog2(N+1)-1){1'b0}}, input_reg[i]};
      end
      bit_count_out = bit_count_out1 + bit_count_out2 + bit_count_out3 + bit_count_out4;
    end
  end

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      // bit_count_int <= '0;
      input_reg <= '0;
      out_addr <= '0;
      // out_valid <= 0;
    end else begin
      // bit_count_int <= bit_count1 + bit_count2;
      out_addr <= in_addr;
      input_reg <= input_data;
      // if (out_valid)
      //   out_valid <= 0;
      // else if (in_valid)
      //   out_valid <= 1;
      out_valid <= in_valid;
    end
  end

endmodule