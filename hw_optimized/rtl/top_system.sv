//-------------------------
// Copyright 2024
// Top-level of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Combines the encoder and associative memory module
//-------------------------
module top_system #(
  parameter int unsigned HV_LENGTH = 2048,
  parameter int unsigned CSR_WIDTH = 32,
  parameter int unsigned CSR_ADDR_WIDTH = 32,
  parameter int unsigned AM_ADDR_WIDTH = 13
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

  // Associative Memory interface
  output logic [AM_ADDR_WIDTH-1:0]    am_addr,
  output logic                        am_ren,
  input  logic [HV_LENGTH-1:0]        am_rdata,
  output logic                        am_wen,
  output logic [HV_LENGTH-1:0]        am_wdata,
  output logic [CSR_WIDTH-1:0]        am_write_addr
);

  // Control and Status Registers (CSR)
  logic start;
  logic running;
  logic soft_reset;
  // I/O
  logic in_valid;   // New input ready to be read
  logic in_ready;  // Ready to receive new input
  logic input_done;
  logic [5:0] in_value;
  logic [4:0] out;
  logic output_valid;
  // Binding
  logic sliding_window_mode;
  logic signature_encoding_mode;
  logic shift_binding_mode;
  logic [5:0] shift_amount_in;
  // Bundling
  logic acc1_mode;
  logic cdt_mode;
  logic acc2_mode;
  logic [5:0] window1_size;
  logic [3:0] cdt_k_factor;
  logic [2:0] thr1_val;
  logic [6:0] thr2_val;
  // AM
  logic [CSR_WIDTH-1:0] am_addr_base;
  logic [CSR_WIDTH-1:0] am_addr_max;

  logic [HV_LENGTH-1:0] encoded_hv;
  logic am_write_encoded;

  // CSR module
  csr #(
    .CSR_WIDTH(CSR_WIDTH),
    .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH),
    .AM_ADDR_WIDTH(AM_ADDR_WIDTH)
  ) csr_i (
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

    .csr_start_o(start),
    .in_valid(in_valid),
    .in_value(in_value),
    .input_done(input_done),

    .running(running),
    .in_ready(in_ready),
    .output_valid(output_valid),
    .out(out),

    .sliding_window_mode(sliding_window_mode),
    .signature_encoding_mode(signature_encoding_mode),
    .shift_binding_mode(shift_binding_mode),
    .shift_amount_in(shift_amount_in),

    .acc1_mode(acc1_mode),
    .cdt_mode(cdt_mode),
    .acc2_mode(acc2_mode),
    .window1_size(window1_size),
    .cdt_k_factor(cdt_k_factor),
    .thr1_val(thr1_val),
    .thr2_val(thr2_val),

    .am_addr_base(am_addr_base),
    .am_addr_max(am_addr_max),
    .am_write_encoded(am_write_encoded),

    .soft_reset(soft_reset)
  );
  
  // Convert window size
  logic [5:0] window1_amount;
  assign window1_amount = window1_size - 1;

  // Mapping module
  logic [5:0] in_value_mapper;
  logic in_valid_mapper;
  logic im_en;
  logic im_zero;
  logic [5:0] shift_amount;
  logic binding_done;
  logic encoding_done;

  // Start & running control
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      running <= 0;
    end else begin
      if (start)
        running <= 1;
      else if (output_valid)
        running <= 0;
    end
  end

  mapper #(
    .HV_LENGTH(HV_LENGTH)
  ) mapper_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .soft_reset(soft_reset),

    .in_valid(in_valid && running),
    .in_value(in_value),
    .running(running),

    .binding_done(binding_done),

    .in_value_mapper(in_value_mapper),
    .in_valid_mapper(in_valid_mapper),
    .in_ready_internal(in_ready),
    .im_en(im_en),
    .im_zero(im_zero),

    .sliding_window_mode(sliding_window_mode),
    .signature_encoding_mode(signature_encoding_mode),
    .shift_amount_in(shift_amount_in),
    .window1_size(window1_amount),

    .shift_amount(shift_amount)
  );

  // Item memory
  logic [HV_LENGTH-1:0] hv_im_out;
  logic im_done;

  item_memory #(
    .HV_LENGTH(HV_LENGTH)
  ) item_memory_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .im_input(in_value_mapper),
    .im_en(im_en),
    .im_zero(im_zero),
    .in_valid(in_valid_mapper),
    
    .im_hv_out(hv_im_out),
    .im_done(im_done)
  );

  // Binding step
  logic [HV_LENGTH-1:0] hv_binding_out;
  logic [5:0] shift_amount_binding;

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shift_amount_binding <= '0;
    end else begin
      shift_amount_binding <= shift_amount;
    end
  end

  binding_op #(
    .HV_LENGTH(HV_LENGTH)
  ) binding_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .im_hv_in(hv_im_out),
    .shift_binding_mode(sliding_window_mode || shift_binding_mode),
    .start_op(im_done),
    .shift_amount(shift_amount_binding),
    .binding_hv_out(hv_binding_out),
    .out_ready(binding_done)
  );

  // Bundling step
  logic [1:0] input_done_queue;
  logic input_done_prev;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      input_done_queue <= '0;
    end else begin
      input_done_queue[0] <= input_done;
      for (int i=0; i<($size(input_done_queue)-1); i++) begin
        input_done_queue[i+1] <= input_done_queue[i];
      end
      if (acc1_mode)
        input_done_prev <= input_done_queue[1];
      else
        input_done_prev <= input_done_queue[0];
    end
  end

  bundling_op #(
  .HV_LENGTH(HV_LENGTH)
  ) bundling_i (
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .soft_reset(soft_reset),
  .hv_in(hv_binding_out),
  .start_op(binding_done),
  .input_done(input_done_prev),
  .input_done_original(input_done),
  .acc1_mode(acc1_mode),
  .cdt_mode(cdt_mode),
  .acc2_mode(acc2_mode),
  .cdt_k_factor(cdt_k_factor),
  .thr1_val(thr1_val),
  .thr2_val(thr2_val),
  .hv_bundling_out(encoded_hv),
  .out_ready(encoding_done),
  .window1_size(window1_amount)
);

// Full AM + comparator logic
logic out_am_valid;
logic am_start;
associative_mem_top #(
  .HV_LENGTH(HV_LENGTH),
  .AM_ADDR_WIDTH(AM_ADDR_WIDTH)
) am_top_i (
  .clk_i(clk_i),
  .rst_ni(rst_ni),

  .encoded_hv(encoded_hv),
  .encoding_done(!am_write_encoded && encoding_done),

  .am_addr(am_addr),
  .am_ren(am_ren),
  .am_rdata(am_rdata),
  .am_addr_base(am_addr_base[AM_ADDR_WIDTH-1:0]),
  .am_addr_max(am_addr_max[AM_ADDR_WIDTH-1:0]),

  .out(out),
  .output_valid(out_am_valid)
);

always_comb begin
  if (am_write_encoded) begin

    if (encoding_done) begin
      am_wen = 1;
      am_wdata = encoded_hv;
      output_valid = 1;
    end else begin
      am_wen = 0;
      output_valid = 0;
      am_wdata = '0;
    end

  end else begin
    output_valid = out_am_valid;
    am_wen = 0;
    am_wdata = '0;
  end

  am_write_addr = am_addr_base;
end

endmodule
