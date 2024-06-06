//-------------------------
// Copyright 2024
// Top wrapper of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Combines the entire accelerator with a memory module
//-------------------------
module top_wrapper #(
  parameter int unsigned HV_LENGTH = 2048,
  parameter int unsigned CSR_WIDTH = 32,
  parameter int unsigned CSR_ADDR_WIDTH = 32,
  parameter int unsigned AM_ADDR_WIDTH = 13 // 32*2048/8 = 2^13 = 8192, use byte addressable memory, so 32x8 = 2^8 addresses per row
)(
  input  logic                        clk_i,
  input  logic                        rst_ni,

  // CSR access
  input  logic [CSR_ADDR_WIDTH-1:0]   csr_addr_i,
  input  logic [CSR_WIDTH-1:0]        csr_wr_data_i,
  input  logic                        csr_wr_en_i,
  input  logic                        csr_req_valid_i,
  output logic                        csr_req_ready_o,
  output logic [CSR_WIDTH-1:0]        csr_rd_data_o,
  output logic                        csr_rsp_valid_o,
  input  logic                        csr_rsp_ready_i,

  // Associative Memory access (from DMA)
  input  logic [47:0]                 ext_am_addr, // 48 bits wide to comply with PULP
  input  logic                        ext_am_wen,
  input  logic                        ext_am_ren,
  input  logic [HV_LENGTH-1:0]        ext_am_wdata,
  output logic [HV_LENGTH-1:0]        ext_am_rdata
);


  // AM interface signals
  logic [AM_ADDR_WIDTH-1:0] am_addr, enc_am_addr;
  logic [CSR_WIDTH-1:0] enc_am_waddr;
  logic am_wen, enc_am_wen;
  logic am_ren, enc_am_ren;
  logic [HV_LENGTH-1:0] am_wdata, enc_am_wdata;
  logic [HV_LENGTH-1:0] am_rdata, enc_am_rdata;

  top_system #(
    .HV_LENGTH(HV_LENGTH),
    .CSR_WIDTH(CSR_WIDTH),
    .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH),
    .AM_ADDR_WIDTH(AM_ADDR_WIDTH)
  ) top_system_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .csr_addr_i(csr_addr_i),
    .csr_wr_data_i(csr_wr_data_i),
    .csr_wr_en_i(csr_wr_en_i),
    .csr_req_valid_i(csr_req_valid_i),
    .csr_req_ready_o(csr_req_ready_o),
    .csr_rd_data_o(csr_rd_data_o),
    .csr_rsp_valid_o(csr_rsp_valid_o),
    .csr_rsp_ready_i(csr_rsp_ready_i),

    .am_addr(enc_am_addr),
    .am_ren(enc_am_ren),
    .am_rdata(enc_am_rdata),
    .am_wen(enc_am_wen),
    .am_wdata(enc_am_wdata),
    .am_write_addr(enc_am_waddr)
  );

  // Associative Memory Interface
  always_comb begin
    if (enc_am_ren) begin
      am_addr = enc_am_addr;
      am_ren = 1;
      enc_am_rdata = am_rdata;
      am_wen = 0;
    end else if (enc_am_wen) begin
      am_addr = enc_am_waddr[AM_ADDR_WIDTH-1:0];
      am_ren = 0;
      am_wen = 1;
      am_wdata = enc_am_wdata;
    end else begin
      am_addr = ext_am_addr[AM_ADDR_WIDTH-1:0];
      am_ren = ext_am_ren;
      ext_am_rdata = am_rdata;
      am_wen = ext_am_wen;
      am_wdata = ext_am_wdata;
    end
 
  end

  // Memory bank (32 x 64x32)
  am_memory #(
    .ADDR_W(AM_ADDR_WIDTH),
    .HV_LENGTH(HV_LENGTH)
  ) am_i (
    .clk_i(clk_i),
    .addr(am_addr),
    .wen(am_wen),
    .ren(am_ren),
    .wdata(am_wdata),
    .rdata(am_rdata)
  );

endmodule
