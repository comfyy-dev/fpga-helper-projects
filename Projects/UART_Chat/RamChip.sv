module RamChip (
	input logic clk,
	input logic write_enable,
	input logic [7:0] data_in,		// Data to write
	input logic [9:0] write_addr,	// Where to write (0-255)
	input logic [9:0] read_addr, 	// Where to read_addr
	output logic [7:0] data_out	// Data being read_addr
);

	// 1. DECLARE THE MEMORY ARRAY
	// 1024 slots, 8 bits wide
	logic [7:0] memory [0:1023];
	
	// 2. INFER THE RAM
	// Quartus detects this specific coding style as RAM
	always_ff @(posedge clk) begin
		// Write port
		if (write_enable) begin
			memory[write_addr] <= data_in;
		end
		
		// Read port
		data_out <= memory[read_addr];
	end

endmodule
