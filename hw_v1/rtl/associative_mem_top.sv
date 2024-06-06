//-------------------------
// Copyright 2024
// Associative memory module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Controls the associative memory interface as well as the comparison logic
//-------------------------

module associative_mem_top #(
  parameter int unsigned HV_LENGTH,
  parameter int unsigned AM_ADDR_WIDTH=13
)(
  input logic clk_i,
  input logic rst_ni,

  input logic [HV_LENGTH-1:0] encoded_hv,
  input logic encoding_done,

  output logic [AM_ADDR_WIDTH-1:0] am_addr,
  output logic am_ren,
  input logic [HV_LENGTH-1:0] am_rdata,
  input logic [AM_ADDR_WIDTH-1:0] am_addr_base,
  input logic [AM_ADDR_WIDTH-1:0] am_addr_max,

  output logic [4:0] out,
  output logic output_valid
);

  // Counter for reading the vectors stored in the AM
  logic reading_am;
  logic [AM_ADDR_WIDTH-1:0] read_am_addr;
  logic [1:0] wait_counter;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      read_am_addr <= '0;
      wait_counter <= '0;
    end else begin

      if (encoding_done) begin
        reading_am <= 1;
        read_am_addr <= am_addr_base;
        wait_counter <= 1;
      end else if ( reading_am && (read_am_addr < am_addr_max) && (wait_counter == 0) ) begin
        read_am_addr <= read_am_addr + 256;
        wait_counter <= 1;
      end else if (wait_counter != 0) begin
        wait_counter <= wait_counter - 1;
      end else begin
        reading_am <= 0;
        read_am_addr <= am_addr_base;
      end

    end
  end
  assign am_addr = read_am_addr;
  assign am_ren = reading_am;

  // AND-array
  logic [HV_LENGTH-1:0] and_out;

  // assign and_out = (reading_am) ? am_rdata & encoded_hv : {HV_LENGTH{1'b0}};
  assign and_out = am_rdata & encoded_hv;

  // Similarity bit counter
  logic [$clog2(HV_LENGTH+1)-1:0] bit_count;
  logic bit_count_valid;
  logic [AM_ADDR_WIDTH-1:0] count_addr;

  bit_counter #(
    .N(HV_LENGTH),
    .AM_ADDR_WIDTH(AM_ADDR_WIDTH)
  ) bit_count_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_valid(reading_am),
    .input_data(and_out),
    .bit_count_out(bit_count),
    .out_valid(bit_count_valid),
    .in_addr(am_addr),
    .out_addr(count_addr)
  );

  // Comparison
  logic [AM_ADDR_WIDTH-1:0] out_addr;
  logic [$clog2(HV_LENGTH+1)-1:0] best_bit_count;
  logic reading_am_prev;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      out_addr <= 0;
      best_bit_count <= 0;
      output_valid <= 0;
      reading_am_prev <= 0;
    end else begin

      reading_am_prev <= reading_am;

      if (reading_am && bit_count_valid) begin

        if (bit_count > best_bit_count) begin
          best_bit_count <= bit_count;
          out_addr <= (count_addr - am_addr_base);
        end

      end

      if (!reading_am && reading_am_prev)
        output_valid <= 1;

      if (output_valid == 1) begin
        output_valid <= 0;
        best_bit_count <= 0;
        out_addr <= 0;
        // bit_count <= '0;
      end

    end
  end
  
  assign out = out_addr[8+:5];

endmodule
