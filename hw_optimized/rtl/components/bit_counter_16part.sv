//-------------------------
// Copyright 2024
// Bit counter module
// Made by: Tim Deboel
// Description: 
// Single cycle bit counter
// Computes the similarity score by counting the overlapping bits
//-------------------------
module bit_counter #(
  parameter int unsigned N = 2048,
  parameter int unsigned AM_ADDR_WIDTH = 13
) (
  input logic clk_i,
  input logic rst_ni,
  input logic in_valid,
  input logic [N-1:0] input_data,
  output logic [$clog2(N)-1:0] bit_count_out,
  output logic out_valid,
  input logic [AM_ADDR_WIDTH-1:0] in_addr,
  output logic [AM_ADDR_WIDTH-1:0] out_addr
);

  // logic [$clog2(N+1)-1:0] bit_count;
  logic [N-1:0] input_reg;

  logic [$clog2(N/16)-1:0] bc1,bc2,bc3,bc4,bc5,bc6,bc7,bc8,bc9,bc10,bc11,bc12,bc13,bc14,bc15,bc16;
  logic [$clog2(N/8)-1:0] b1,b2,b3,b4,b5,b6,b7,b8;
  logic [$clog2(N/4)-1:0] c1,c2,c3,c4;
  logic [$clog2(N/2)-1:0] d1,d2;

  always_comb begin
    // bit_count = '0;
    bc1 = '0;
    bc2 = '0;
    bc3 = '0;
    bc4 = '0;
    bc5 = '0;
    bc6 = '0;
    bc7 = '0;
    bc8 = '0;
    bc9 = '0;
    bc10 = '0;
    bc11 = '0;
    bc12 = '0;
    bc13 = '0;
    bc14 = '0;
    bc15 = '0;
    bc16 = '0;
    if (in_valid) begin
      for (integer i = 0; i < N/16; i = i + 1) begin
        bc1 = bc1 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N/16; i < N*2/16; i = i + 1) begin
        bc2 = bc2 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*2/16; i < N*3/16; i = i + 1) begin
        bc3 = bc3 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*3/16; i < N*4/16; i = i + 1) begin
        bc4 = bc4 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*4/16; i < N*5/16; i = i + 1) begin
        bc5 = bc5 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*5/16; i < N*6/16; i = i + 1) begin
        bc6 = bc6 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*6/16; i < N*7/16; i = i + 1) begin
        bc7 = bc7 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*7/16; i < N*8/16; i = i + 1) begin
        bc8 = bc8 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*8/16; i < N*9/16; i = i + 1) begin
        bc9 = bc9 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*9/16; i < N*10/16; i = i + 1) begin
        bc10 = bc10 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*10/16; i < N*11/16; i = i + 1) begin
        bc11 = bc11 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*11/16; i < N*12/16; i = i + 1) begin
        bc12 = bc12 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*12/16; i < N*13/16; i = i + 1) begin
        bc13 = bc13 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*13/16; i < N*14/16; i = i + 1) begin
        bc14 = bc14 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*14/16; i < N*15/16; i = i + 1) begin
        bc15 = bc15 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      for (integer i = N*15/16; i < N; i = i + 1) begin
        bc16 = bc16 + {{($clog2(N/16)-1){1'b0}}, input_reg[i]};
      end
      b1=bc1+bc2;
      b2=bc3+bc4;
      b3=bc5+bc6;
      b4=bc7+bc8;
      b5=bc9+bc10;
      b6=bc11+bc12;
      b7=bc13+bc14;
      b8=bc15+bc16;
      c1=b1+b2;
      c2=b3+b4;
      c3=b5+b6;
      c4=b7+b8;
      d1=c1+c2;
      d2=c3+c4;
      bit_count_out = d1+d2;
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