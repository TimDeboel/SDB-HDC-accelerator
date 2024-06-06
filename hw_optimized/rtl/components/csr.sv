//-------------------------
// Control-Status-Register for the programmable SBD-HDC accelerator
// Made by: Tim Deboel
// Description: 
// CSR manager
//-------------------------
// Description of CSR set:
// ----- CSR Name ----- | ----- Address ----- | -------------------------- Description --------------------------
//      CSR_START       |          0          | Starts the accelerator. Write 1 to activate. Reads return 0
//      CSR_INPUT       |          1          | b0 input_valid, b1-6 in_value, b7-12 shift_amount, b13 input_done
//      CSR_STATUS      |          2          | b0 running, b1 ready to receive new input, b2 if output valid, b3-7 output value
//      CSR_P_BINDING   |          3          | Program binding: b0 sliding_window_mode, b1 signature_encoding_mode, b2 shift_binding_mode
//      CSR_P_BUNDLING  |          4          | Program bundling: b0 acc1_mode, b1 cdt_mode, b2 acc2_mode, b3-8 window1_size, b9-12 cdt_k_factor, b13-15 thr1, b16-22 thr2, n23 am_write_enable
//      CSR_AM_BASE     |          5          | b0-31 base address of loaded AM, b13-25 base address of loaded HV
//      CSR_AM_MAX      |          6          | b0-31 base address of loaded AM, b13-25 max address of loaded HV
//      CSR_RESET       |          7          | b0 resets the accelerator. Reads return 0
//---------------------------------------------------------------------------------------------------------------
module csr #(
  parameter int unsigned CSR_WIDTH = 32,
  parameter int unsigned CSR_ADDR_WIDTH = 32,
  parameter int unsigned AM_ADDR_WIDTH = 13
)(
  input  logic                    clk_i,
  input  logic                    rst_ni,
  // CSR control signals
  input  logic [CSR_ADDR_WIDTH-1:0] csr_addr_i,
  input  logic [CSR_WIDTH-1:0]      csr_wr_data_i,
  input  logic                      csr_wr_en_i,
  input  logic                      csr_req_valid_i,
  output logic                      csr_req_ready_o,
  output logic [CSR_WIDTH-1:0]      csr_rd_data_o,
  output logic                      csr_rsp_valid_o,
  input  logic                      csr_rsp_ready_i,
  // Register I/O to accelerator
  output logic                      csr_start_o,

  // Decoded I/O
  output logic        in_valid,
  output logic [5:0]  in_value,
  output logic        input_done,

  input  logic        running,
  input  logic        in_ready,
  input  logic        output_valid,
  input  logic [4:0]  out,

  output logic        sliding_window_mode,
  output logic        signature_encoding_mode,
  output logic        shift_binding_mode,
  output logic [5:0]  shift_amount_in,

  output logic        acc1_mode,
  output logic        cdt_mode,
  output logic        acc2_mode,
  output logic [5:0]  window1_size,
  output logic [3:0]  cdt_k_factor,
  output logic [2:0]  thr1_val,
  output logic [6:0]  thr2_val,

  output logic [CSR_WIDTH-1:0]  am_addr_base,
  output logic [CSR_WIDTH-1:0]  am_addr_max,
  output logic        am_write_encoded,

  output logic        soft_reset
);
  //-------------------------------
  // Register parameters
  //-------------------------------
  localparam int unsigned CSR_START       = 32'd0;
  localparam int unsigned CSR_INPUT       = 32'd1;
  localparam int unsigned CSR_STATUS      = 32'd2;
  localparam int unsigned CSR_P_BINDING   = 32'd3;
  localparam int unsigned CSR_P_BUNDLING  = 32'd4;
  localparam int unsigned CSR_AM_BASE     = 32'd5;
  localparam int unsigned CSR_AM_MAX      = 32'd6;
  localparam int unsigned CSR_RESET       = 32'd7;
  // Decode registers into accelerator inputs
  logic [CSR_WIDTH-1:0]      csr_input_o;
  logic [CSR_WIDTH-1:0]      csr_status_i;
  logic [CSR_WIDTH-1:0]      csr_p_binding_o;
  logic [CSR_WIDTH-1:0]      csr_p_bundling_o;
  logic [CSR_WIDTH-1:0]      csr_am_base_o;
  logic [CSR_WIDTH-1:0]      csr_am_max_o;
  logic [CSR_WIDTH-1:0]      csr_soft_reset_o;
  always_comb begin
    // General input
    in_valid        = csr_input_o[0];
    in_value        = csr_input_o[6:1];
    shift_amount_in = csr_input_o[12:7];
    input_done      = csr_input_o[13];
    // Status output
    csr_status_i[0]   = running;
    csr_status_i[1]   = in_ready && running;
    csr_status_i[2]   = output_valid;
    csr_status_i[7:3] = out;
    csr_status_i[CSR_WIDTH-1:8] = '0;
    // Binding input
    sliding_window_mode     = csr_p_binding_o[0];
    signature_encoding_mode = csr_p_binding_o[1];
    shift_binding_mode      = csr_p_binding_o[2];
    // Bundling input
    acc1_mode         = csr_p_bundling_o[0];
    cdt_mode          = csr_p_bundling_o[1];
    acc2_mode         = csr_p_bundling_o[2];
    window1_size      = csr_p_bundling_o[8:3];
    cdt_k_factor      = csr_p_bundling_o[12:9];
    thr1_val          = csr_p_bundling_o[15:13];
    thr2_val          = csr_p_bundling_o[22:16];
    am_write_encoded  = csr_p_bundling_o[23];
    // AM
    am_addr_base  = csr_am_base_o;
    am_addr_max   = csr_am_max_o;

    soft_reset    = !csr_soft_reset_o[0];
  end
  //-------------------------------
  // Control signals
  //-------------------------------
  logic req_success;
  // Ready signal is dependent if the accelerator
  // is busy or not. Status == 1 means it's free.
  // Status == 0 means it's busy.
  assign csr_req_ready_o = csr_status_i[1];
  // Standard valid-ready response
  // We'll only accept new registers when they are ready
  // assign req_success = csr_req_valid_i && csr_req_ready_o;
  assign req_success = csr_req_valid_i;
  //-------------------------------
  // Updating CSR registers
  //-------------------------------
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
      csr_input_o       <= '0;
      csr_p_binding_o   <= '0;
      csr_p_bundling_o  <= '0;
      csr_am_base_o     <= '0;
      csr_am_max_o      <= '0;
      csr_soft_reset_o  <= '0;
    end else begin
      if(req_success && csr_wr_en_i) begin
        case(csr_addr_i)
          CSR_INPUT:        csr_input_o       <= csr_wr_data_i;
          CSR_P_BINDING:    csr_p_binding_o   <= csr_wr_data_i;
          CSR_P_BUNDLING:   csr_p_bundling_o  <= csr_wr_data_i;
          CSR_AM_BASE:      csr_am_base_o     <= csr_wr_data_i;
          CSR_AM_MAX:       csr_am_max_o      <= csr_wr_data_i;
          CSR_RESET:        begin
            if (csr_soft_reset_o[0] == 0)
              csr_soft_reset_o  <= csr_wr_data_i;
            else
              csr_soft_reset_o  <= 0;
          end
          default: begin
            csr_input_o       <= csr_input_o;
            csr_p_binding_o   <= csr_p_binding_o;
            csr_p_bundling_o  <= csr_p_bundling_o;
            csr_am_base_o     <= csr_am_base_o;
            csr_am_max_o      <= csr_am_max_o;
            csr_soft_reset_o  <= '0;
          end
        endcase
      end
      if (csr_soft_reset_o[0] == 1)
        csr_soft_reset_o <= '0;
    end
  end
  //-------------------------------
  // Fully combinational assignments
  //-------------------------------
  assign csr_start_o = req_success && 
                       csr_wr_en_i &&
                       (csr_addr_i == CSR_START)&&
                       csr_wr_data_i[0];
  //-------------------------------
  // Since RISCV CSR instructions
  // an automatic read and write
  // every cycle of a request,
  // the next cycle gives a valid data out
  // The output read data is registered
  //-------------------------------
  logic rsp_success;
  assign rsp_success = csr_rsp_valid_o && csr_rsp_ready_i;
  always_comb begin
    // Decode the response
    case(csr_addr_i)
      CSR_START:      csr_rd_data_o = '0;
      CSR_INPUT:      csr_rd_data_o = csr_input_o;
      CSR_STATUS:     csr_rd_data_o = csr_status_i;
      CSR_P_BINDING:  csr_rd_data_o = csr_p_binding_o;
      CSR_P_BUNDLING: csr_rd_data_o = csr_p_bundling_o;
      CSR_AM_BASE:    csr_rd_data_o = csr_am_base_o;
      CSR_AM_MAX:     csr_rd_data_o = csr_am_max_o;
      default:        csr_rd_data_o = '0;
    endcase
    csr_rsp_valid_o = csr_req_valid_i;
  end
endmodule