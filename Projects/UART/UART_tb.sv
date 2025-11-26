`timescale 1ns/1ns

module UART_tb;

	logic clk = 0;
	logic rx_line = 1; // Serial lines idle highz0
	logic [7:0] data_out;
	logic valid_out;
	
	// Instantiate the reciever
	
	UART_RX uut (
		.clk(clk),
		.rx_serial(rx_line),
		.rx_byte(data_out),
		.rx_dv(valid_out)
	);
	
	// Generate 50MHz clock
	always #10 clk = ~clk;
	
	// CONSTANT: Bit period for 9600 Baud
	// 1 sec / 9600 = 104160 ns
	localparam BIT_PERIOD = 104160;
	
	// TASK: Helper function to send a byte
	task UART_SEND_BYTE(input [7:0] byte_to_send);
		integer i;
		begin
			// 1. Start bit (low)
			rx_line = 0;
			#(BIT_PERIOD);
			
			// 2. Data bits (LSB first)
			for (i=0;i<8;i=i+1) begin
				rx_line = byte_to_send[i]; // Send bit i
				#(BIT_PERIOD);					 // wait 1 bit time
			end
			
			// 3. Stop bit (high)
			rx_line = 1;
			#(BIT_PERIOD);
		end
	endtask
	
	// MAIN TEST
	initial begin
		// Wait a bit
		#1000;
		
		// Send the letter 'A' (0x41 = 01000001)
		UART_SEND_BYTE(8'h41);
		
		// Wait a bit
		#1000;
		
		// Send the letter 'B' (0x42 = 01000010)
		UART_SEND_BYTE(8'h42);
		
		#10000;
		$stop;
	end
	
endmodule
