//-------------------------
// Copyright 2024
// bundling operator module of the programmable sparse HDC accelerator
// Made by: Tim Deboel
// Description: 
// Consists of a superposition (OR) module, a CDT operator, 2 accumulators
//-------------------------
module bundling_op #(
  parameter int unsigned HV_LENGTH = 2048,
  // parameter int unsigned ACC1_SIZE = 3, // 2b saturating acc, for majority >=4 (window size 8 at 50%)
  // // 2b saturating acc, 3rd bit to indicate "saturated" (stop adding when this is 1)
  // // saturate after >3 vectors
  parameter int unsigned ACC1_SIZE = 4,
  parameter int unsigned ACC2_COUNT = 11, // max 1024 input characters allowed
  parameter int unsigned ACC2_SIZE = 8 // Saturate at 128 (TODO possibly lower this, but restricts flexibility)
)(
  input logic                   clk_i,
  input logic                   rst_ni,
  input logic                   soft_reset,

  input logic [HV_LENGTH-1:0]   hv_in,
  input logic                   start_op,
  input logic                   input_done,
  // input logic                   segment_mode, // Segment mode
  input logic                   or_mode,      // enable OR array
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
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      in_counter <= 6'd0;
    end else begin
      if (!soft_reset) begin
        in_counter <= 6'd0;
      end else if (or_mode || acc1_mode) begin

        if ( start_op && (in_counter == 0) )
          in_counter <= window1_size;
        else if ( start_op && (in_counter > 0) )
          in_counter <= in_counter - 1;

      end
    end
  end

  
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
            if (hv_in[i] == 1'b1) begin
              if (acc1_regs[i][ACC1_SIZE-1] == 1'b0)  // Acc not saturated
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
  always_comb begin
    if (acc1_mode && in_counter == 0) begin
      for (int i=0; i<$size(acc1_regs); i++) begin
        if ((acc1_regs[i][ACC1_SIZE-1] == 1'b1) || (acc1_regs[i] >= thr1_val))
          thr1_out[i] = 1'b1;
        else
          thr1_out[i] = 1'b0;
      end
    end else
      thr1_out = '0;
  end

        


  // TODO integrate with accumulator regs
  // OR array
  // assign or_out = (or_mode) ? (hv_in | reg1_out) : im_hv_in;
  logic [HV_LENGTH-1:0] reg1_out;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      reg1_out <= {HV_LENGTH{1'b0}};
    end else begin
      if (or_mode) begin
        if (start_op && in_counter == 0)
          reg1_out <= hv_in;
        else if (start_op && in_counter > 0)
          reg1_out <= (reg1_out | hv_in);
          
      end else if (acc1_mode)
        reg1_out <= thr1_out; // TODO don't store thr1_out in separate reg but use immediately
      else if (start_op)
        reg1_out <= hv_in;

    end
  end
      
  
  // Context Dependent Thinning operation
  // TODO implement k-factor
  // TODO reuse OR?
  // logic [HV_LENGTH-1:0] cdt_out;
  // logic [HV_LENGTH-1:0] cdt_reg;
  // logic [3:0] k_counter;
  // logic [HV_LENGTH-1:0] cdt_sh_out;
  // logic cdt_done;
  // logic in_counter_prev_one;
  // always_comb begin
  //   if ( cdt_mode && (k_counter > 0 || in_counter == 0) )
  //   case (k_counter)
  //     3'd1: cdt_sh_out = {reg1_out[0], reg1_out[HV_LENGTH-1:1]};
  //     3'd2: cdt_sh_out = {reg1_out[1:0], reg1_out[HV_LENGTH-1:2]};
  //     3'd3: cdt_sh_out = {reg1_out[2:0], reg1_out[HV_LENGTH-1:3]};
  //     3'd4: cdt_sh_out = {reg1_out[3:0], reg1_out[HV_LENGTH-1:4]};
  //     3'd5: cdt_sh_out = {reg1_out[4:0], reg1_out[HV_LENGTH-1:5]};
  //     3'd6: cdt_sh_out = {reg1_out[5:0], reg1_out[HV_LENGTH-1:6]};
  //     3'd7: cdt_sh_out = {reg1_out[6:0], reg1_out[HV_LENGTH-1:7]};
  //     default: cdt_sh_out = {reg1_out[0], reg1_out[HV_LENGTH-1:1]};
  //   endcase
  // end
  // always_ff @ (posedge clk_i or negedge rst_ni) begin
  //   if (!rst_ni) begin
  //     cdt_reg <= {HV_LENGTH{1'b0}};
  //     k_counter <= '0;
  //     cdt_done <= 0;
  //     in_counter_prev_one <= 0;
  //   end else begin
  //     if (!soft_reset) begin
  //       cdt_reg <= {HV_LENGTH{1'b0}};
  //       k_counter <= '0;
  //       cdt_done <= 0;
  //       in_counter_prev_one <= 0;
  //     end else if (cdt_mode) begin

  //       in_counter_prev_one <= (in_counter == 1);

  //       if ( (in_counter == 0 && in_counter_prev_one) || (in_counter == 0 && start_op_prev && !or_mode && !acc1_mode)) begin //TODO fix for when no cdt or acc1 enabled
  //         if (cdt_k_factor == 1) begin
  //           cdt_reg <= cdt_reg | {reg1_out[0], reg1_out[HV_LENGTH-1:1]};
  //           cdt_done <= 1;
  //         end else begin
  //           k_counter <= cdt_k_factor;
  //           cdt_reg <= reg1_out;
  //         end

  //       end else if (k_counter > 1) begin
  //         cdt_reg <= cdt_reg | cdt_sh_out;
  //         k_counter <= k_counter - 1;
  //       end else if (k_counter == 1) begin
  //         cdt_reg <= cdt_reg | cdt_sh_out;
  //         k_counter <= '0;
  //         cdt_done <= 1;
  //       end else begin
  //         cdt_done <= 0;
  //       end

  //     end
  //   end
  // end
  // assign cdt_out = cdt_reg & reg1_out;

  logic [HV_LENGTH-1:0] cdt_out;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      cdt_out <= '0;
    end else if (cdt_mode) begin

      if (in_counter == 0) begin
        case(cdt_k_factor)
          2'd1: cdt_out <= ( reg1_out & {reg1_out[0], reg1_out[HV_LENGTH-1:1]} );
          2'd2: cdt_out <= ( reg1_out & ( {reg1_out[0], reg1_out[HV_LENGTH-1:1]} | {reg1_out[1:0], reg1_out[HV_LENGTH-1:2]} ) );
          2'd3: cdt_out <= ( reg1_out & ( {reg1_out[0], reg1_out[HV_LENGTH-1:1]} | {reg1_out[1:0], reg1_out[HV_LENGTH-1:2]} | {reg1_out[2:0], reg1_out[HV_LENGTH-1:3]} ) );
          default: cdt_out <= reg1_out;
        endcase
      end else begin
        cdt_out <= '0;
      end

    end
  end


  logic [HV_LENGTH-1:0] stage1_out;
  assign stage1_out = cdt_mode ? cdt_out : reg1_out;

  // Stage1 ready signal
  wire cond1;
  assign cond1 = (in_counter == 1 && start_op);
  // logic cond1_prev;
  logic start_op_prev;
  logic cond2;
  logic cond2_prev;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // cond1_prev <= 0;
      start_op_prev <= 0;
      cond2_prev <= 0;
    end else begin
      // cond1_prev <= cond1;
      start_op_prev <= start_op;
      cond2_prev <= cond2;
    end
  end
  assign cond2 = (in_counter == 0 && start_op_prev);

  // TODO clean up
  logic stage1_ready;
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      stage1_ready <= 0;
    end else begin
      if (or_mode)
        begin
        if (!cdt_mode && cond1)
          stage1_ready <= 1;
        else if (cdt_mode && cond2)
          stage1_ready <= 1;
        else
          stage1_ready <= 0;
        end 
      else if (acc1_mode) 
        begin
          if ((!cdt_mode && cond2) || (cdt_mode && cond2_prev))
            stage1_ready <= 1;
          else
            stage1_ready <= 0;
        end 
      else if (cdt_mode)
        begin
          if (cond2)
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
  // So take 1024 max
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
            if (stage1_out[i] == 1'b1) begin
              if (acc2_regs[i][ACC2_SIZE-1] == 1'b0)  // Acc not saturated
                acc2_regs[i] <= acc2_regs[i] + 1'b1;
            end
          end
        end

      end
    end
  end


  // Thresholding 2
  logic [ACC2_SIZE-1:0] thr2_effective;
  logic [16:0] thr2_calc;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      thr2_calc <= 0; // Systemverilog array assignment to all zeros
    end else begin

      if (acc2_mode && stage1_ready) begin
        thr2_calc <= (thr2_val*(acc2_counter+1));
      end
      
    end
  end
  assign thr2_effective = thr2_calc >> 10;

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
        if ((acc2_regs[i][ACC2_SIZE-1] == 1'b1) || (acc2_regs[i] > thr2_effective))
          thr2_out[i] = 1'b1;
        else
          thr2_out[i] = 1'b0;
      end

    end

  end


  // Output control
  // TODO CAREFUL THAT AM TAKES THE RIGHT VALUE (bug in encode wait 1 clk)
  always_ff @ (posedge clk_i or negedge rst_ni) begin
    if ( !rst_ni ) begin
      hv_bundling_out <= 0;
    end else begin
      if (acc2_mode) begin
        if (stage1_ready_prev)
          hv_bundling_out <= thr2_out;
      // else if (cdt_mode && stage1_ready)
      //   hv_bundling_out <= cdt_out;
      end else if (stage1_ready)
        hv_bundling_out <= stage1_out;
    end
  end
  // always_comb begin
  //   if (acc2_mode)
  //     hv_bundling_out = thr2_out;
  //   else if (cdt_mode)
  //     hv_bundling_out = cdt_out;
  //   else
  //     hv_bundling_out = reg1_out;
  // end

  // TODO char 1 cycle shorter? Lang maybe not possible
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
        out_ready <= stage1_ready_prev;
      end

    end
  end


endmodule
