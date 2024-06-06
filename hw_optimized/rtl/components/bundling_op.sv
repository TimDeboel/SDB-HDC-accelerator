//-------------------------
// Copyright 2024
// bundling operator module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Consists of two stages:
// First stage contains an accumulator with thresholding followed by CDT
// Second stage contains a larger accumulator with a thresholding function
//-------------------------
module bundling_op #(
  parameter int unsigned HV_LENGTH = 2048,
  parameter int unsigned ACC1_SIZE = 4,// 3b saturating acc, for majority >=8 (window size 16 at 50%)
  // 3b saturating acc, 4th bit to indicate "saturated" (stop adding when this is 1)
  // can saturate after a minimum of 8 vectors
  parameter int unsigned ACC2_COUNT = 11, // max 2048 input characters allowed
  parameter int unsigned ACC2_SIZE = 8 // Saturate at 128 (Lowering this restricts flexibility)
)(
  input logic                   clk_i,
  input logic                   rst_ni,
  input logic                   soft_reset,

  input logic [HV_LENGTH-1:0]   hv_in,
  input logic                   start_op,
  input logic                   input_done,
  input logic                   input_done_original,

  input logic                   acc1_mode,
  input logic                   cdt_mode,
  input logic                   acc2_mode,
  input logic [3:0]             cdt_k_factor,
  input logic [2:0]             thr1_val,
  input logic [6:0]             thr2_val,
  input logic [5:0]             window1_size,
  output logic [HV_LENGTH-1:0]  hv_bundling_out,
  output logic                  out_ready
);

  // Input counter reg
  logic [5:0] in_counter;
  logic [5:0] in_counter_prev;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      in_counter <= 6'd0;
      in_counter_prev <= 6'd0;
    end else begin
      if (!soft_reset) begin
        in_counter <= 6'd0;
        in_counter_prev <= 6'd0;
      end else if (acc1_mode) begin
        in_counter_prev <= in_counter;

        if (start_op) begin
          if (in_counter == 0) 
            in_counter <= window1_size;
          else if (in_counter > 0)
            in_counter <= in_counter - 1;
        end

      end
    end
  end

  logic in_counter_zero;
  assign in_counter_zero = (cdt_mode) ? (in_counter == 0 && in_counter_prev != 0) : '0;
  
  // Saturating accumulator 1
  logic [ACC1_SIZE-1:0] acc1_regs [HV_LENGTH-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      acc1_regs <= '{default:'0}; // Systemverilog array assignment to all zeros
    end else begin
      if (!soft_reset) begin
        acc1_regs <= '{default:'0};
      end else if (acc1_mode) begin

        if (start_op && in_counter > 0) begin
          for (int i=0; i<$size(acc1_regs); i++) begin
            if (hv_in[i] == 1'b1 && acc1_regs[i][ACC1_SIZE-1] == 1'b0) begin // Acc not saturated
              acc1_regs[i] <= acc1_regs[i] + 1'b1;
            end
          end

        end else if (start_op && in_counter == 0) begin
          for (int i=0; i<$size(acc1_regs); i++) begin
            acc1_regs[i] <= {'0,hv_in[i]};
          end
        end

      end
    end
  end

  // Thresholding 1
  logic [HV_LENGTH-1:0] thr1_out;
  logic [ACC1_SIZE-1:0] thr1_effective;
  always_comb begin
    thr1_effective = (thr1_val == 0) ? 1 : thr1_val;  // Switch thr to 1 if its set to zero

    if (acc1_mode) begin
      if (in_counter == 0) begin
          for (int i=0; i<$size(acc1_regs); i++) begin
          if ((acc1_regs[i][ACC1_SIZE-1] == 1'b1) || (acc1_regs[i] >= thr1_effective))
            thr1_out[i] = 1'b1;
          else
            thr1_out[i] = 1'b0;
          end
        end
    end
  end


  logic [HV_LENGTH-1:0] reg1_out;
  always_comb begin
    if (acc1_mode) begin
      reg1_out = thr1_out;
    end else begin
      reg1_out = hv_in;
    end
  end


  logic [HV_LENGTH-1:0] cdt_out;
  cdt #(
    .HV_LENGTH(HV_LENGTH)
  ) cdt_i (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .cdt_mode(cdt_mode),
    .acc1_mode(acc1_mode),
    .in_counter_prev_zero(in_counter_zero),
    .cdt_k_factor(cdt_k_factor),

    .cdt_in(reg1_out),
    .cdt_out(cdt_out)
  );


  logic [HV_LENGTH-1:0] stage1_out;
  assign stage1_out = cdt_mode ? cdt_out : reg1_out;

  // Stage1 ready signal
  wire cond1;
  assign cond1 = (in_counter == 1 && start_op);

  // Stage1 output control
  logic stage1_ready;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      stage1_ready <= 0;
    end else begin
      if (acc1_mode) 
        begin
          if (cond1)
            stage1_ready <= 1;
          else
            stage1_ready <= 0;
        end
      else if (start_op)
        stage1_ready <= 1;
      else
        stage1_ready <= 0;
      
    end
  end


  // Acc2 counter reg
  // Longest file 1139 characters, 2nd longest 975
  // So take 2048 max
  logic [ACC2_COUNT-1:0] acc2_counter;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      acc2_counter <= '0;
    end else begin
      if (!soft_reset) begin
        acc2_counter <= '0;
      end else if (acc2_mode) begin

        if (acc2_counter < {(ACC2_COUNT){1'b1}}) begin
          if (stage1_ready)
            acc2_counter <= acc2_counter + 1;
        end

      end
    end
  end


  // Saturating accumulator 2
  logic [ACC2_SIZE-1:0] acc2_regs [HV_LENGTH-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      acc2_regs <= '{default:'0}; // Systemverilog array assignment to all zeros
    end else begin
      if (!soft_reset) begin
        acc2_regs <= '{default:'0};
      end else if (acc2_mode) begin

        if (stage1_ready) begin
          for (int i=0; i<$size(acc2_regs); i++) begin
            if (stage1_out[i] == 1'b1 && acc2_regs[i][ACC2_SIZE-1] == 1'b0) begin // Acc not saturated
              acc2_regs[i] <= acc2_regs[i] + 1'b1;
            end
          end
        end

      end
    end
  end


  // Thresholding 2
  logic [ACC2_SIZE-1:0] thr2_effective;
  logic [ACC2_SIZE:0] thr2_small;
  logic [17:0] thr2_calc; // Needs to handle 127*2048 worst case
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      thr2_calc <= 0; // Systemverilog array assignment to all zeros
    end else begin

      if (acc2_mode && stage1_ready && input_done_original) begin
        thr2_calc <= (thr2_val*(acc2_counter+1));
      end
      
    end
  end
  assign thr2_small = thr2_calc >> 10;
  assign thr2_effective = (thr2_small < 8'd128) ? thr2_small : 8'd127; // Acc2 saturates at 128, so keep thr below to pass all saturated values

  // Control signals
  logic stage1_ready_prev;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni )
      stage1_ready_prev <= 0; // Systemverilog array assignment to all zeros
    else 
      stage1_ready_prev <= stage1_ready;
  end

  logic [HV_LENGTH-1:0] thr2_out;
  always_comb begin
    if (acc2_mode && input_done && stage1_ready_prev) begin

      for (int i=0; i<$size(acc2_regs); i++) begin
        if (acc2_regs[i] > thr2_effective)
          thr2_out[i] = 1'b1;
        else
          thr2_out[i] = 1'b0;
      end

    end
  end


  // Output control
  always_comb begin
    if (acc2_mode)
      hv_bundling_out = thr2_out;
    else
      hv_bundling_out = stage1_out;
  end

  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      out_ready <= 0;
    end else begin

      if (acc2_mode) begin
        if (input_done && stage1_ready_prev)
          out_ready <= 1;
        else
          out_ready <= 0;

      end else begin
        out_ready <= stage1_ready;
      end

    end
  end


endmodule
