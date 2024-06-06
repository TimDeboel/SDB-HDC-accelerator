// OpenRAM SRAM model (modified)
// Words: 32
// Word size: 64

module sky130_sram_64x32(
// `ifdef USE_POWER_PINS
//     vccd1,
//     vssd1,
// `endif
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0
  );

  parameter DATA_WIDTH = 64 ;
  parameter ADDR_WIDTH = 5 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  // FIXME: This delay is arbitrary.
  parameter DELAY = 0 ;
  parameter VERBOSE = 1 ; //Set to 0 to only display warnings
  parameter T_HOLD = 1 ; //Delay to hold dout value after posedge. Value is arbitrary

// `ifdef USE_POWER_PINS
//     inout vccd1;
//     inout vssd1;
// `endif
  input  clk0; // clock
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;

  reg [DATA_WIDTH-1:0]  dout0;
  reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (negedge clk0)
  begin : MEM_WRITE0
    if ( !csb0 && !web0 ) begin
        mem[addr0][63:0] <= din0[63:0];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  // always @ (csb0 or web0 or mem[addr0])
  always_comb
  begin : MEM_READ0
    if (!csb0 && web0)
       dout0 = mem[addr0];
    else
       dout0 = 'bx;
  end


endmodule
