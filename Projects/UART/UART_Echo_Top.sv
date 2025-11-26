module UART_Echo_Top (
	input logic clk,
	input logic rst_n,
	input logic rx_serial,
	output logic tx_serial,
	output logic [7:0] seg,
	output logic [3:0] dig
);

	// 1. WIRES to connect RX to TX
	logic [7:0] received_byte;
	logic byte_ready;
	
	// 2. Instantiate receiver
	UART_RX RX_Module (
		.clk(clk),
		.rx_serial(rx_serial),
		.rx_byte(received_byte),
		.rx_dv(byte_ready)
	);
	
	// 3. Instantiate Transmitter
	UART_TX TX_Module (
		.clk(clk),
		.tx_start(byte_ready),		// Trigger send when data arrives
		.tx_byte(received_byte),	// Loop the data back
		.tx_serial(tx_serial),
		.tx_busy()						// We ignore busy signal for simple echo
	);
	
	// 4. Visal DEBUG (display ASCII byte)
	// We need to split the 8-bit byte into two 4-bit nibbles
	logic [3:0] upper_nibble;
   logic [3:0] lower_nibble;
	assign upper_nibble = received_byte[7:4];
	assign lower_nibble = received_byte[3:0];
	
	// Reuse display driver
	
	Display_Driver Debug_Display (
		.clk(clk),
		.in0(lower_nibble),
		.in1(upper_nibble),
		.in2(4'd0),
		.in3(4'd0),
		.dig_sel(dig),
		.seg_out(seg)
	);
	
endmodule
	
