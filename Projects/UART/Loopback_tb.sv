`timescale 1ns/1ns

module Loopback_tb;

	logic clk = 0;
	
	// TX I/O
	logic [7:0] data_in = 8'h4B; // K in hex
	logic tx_start = 0;
	logic tx_busy;
	
	// Virtual cable
	logic serial_line;
	
	// RX Outputs
	logic [7:0] data_out;
	logic rx_done;
	
	always #10 clk = ~clk;
	
	UART_TX master_tx (
		.clk(clk),
		.tx_start(tx_start),
		.tx_byte(data_in),
		.tx_serial(serial_line), // connect to the wire
		.tx_busy(tx_busy)
	);
	
	UART_RX slave_rx (
		.clk(clk),
		.rx_serial(serial_line), // Connect to the same wire
		.rx_byte(data_out),
		.rx_dv(rx_done)
	);
	
	// Testbed
	initial begin
		#1000 // let system settle
		$dispay("Sending byte: %h ('K')", data_in);
		
		tx_start = 1;
		#20 // hold for one full clock cycle
		tx_start = 0;
		
		// Wait for the RX module to finish
		// The @(posedge signal) command pauses simulation until that signal goes high
		@(posedge rx_done);
		
		$dispay("Received byte: %h", data_out);
		
		if (data_out == data_in) $display("TEST PASSED: Loopback successful!");
		else $display("TEST FAILED: Data mismatch.");
		
		#1000;
		$stop;
	end
	
endmodule
		
		