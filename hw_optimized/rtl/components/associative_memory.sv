//-------------------------
// Copyright 2024
// Associative memory module
// Made by: Tim Deboel
// Description: 
// Memory module for functional testing of the AM interface
//-------------------------

// 2048 = 8*256 bits -> 256*32 = 2^13 -> 13 bit address width required to address all bytes for 32 HVs
module am_memory#(
   parameter int unsigned ADDR_W = 13,
   parameter int unsigned HV_LENGTH
) (
   input wire			            clk_i,
   input wire  [ADDR_W-1:0]      addr,
   input wire                    wen,
   input wire                    ren,
   input wire  [HV_LENGTH-1:0]   wdata,
   output reg  [HV_LENGTH-1:0]   rdata

   );
parameter integer MACRO_DEPTH = 32;
parameter integer WORD_SIZE = 64;
parameter integer N_MEMS      = (32 * HV_LENGTH)/(MACRO_DEPTH*WORD_SIZE);

reg [4:0] addr_i;
reg web, csb;

always_comb begin   
   addr_i      = addr[8+:(ADDR_W-8)]; // Jump addr every 2048 bits or 256 bytes
   web        = (~wen) | ren ;
   csb        = wen ~^ ren; // Can only read OR write at a time
end

genvar index_depth;
generate
   for (index_depth = 0; index_depth < N_MEMS; index_depth = index_depth+1) begin: process_for_mem

         sky130_sram_64x32 skyram_inst( 
            .clk0    ( ~clk_i                                     ),
            .csb0    ( csb                                        ),
            .web0    ( web                                        ),
            .addr0   ( addr_i                                     ),
            .din0    ( wdata[64*(index_depth+1)-1:64*index_depth] ),
            .dout0   ( rdata[64*(index_depth+1)-1:64*index_depth] )
         );
      
   end
endgenerate
	
endmodule
