module UART_TX (
	input logic clk,
	input logic tx_start,		// Pulse this to send a byte
	input logic [7:0] tx_byte,	// This byte to send
	output logic tx_serial,		// The physical wire
	output logic tx_busy			// High while sending (dont send new data yet)
);

	parameter CLKS_PER_BIT = 5208; // 9600 Baud
	
	typedef enum logic [2:0] {
		IDLE,
		START_BIT,
		DATA_BITS,
		STOP_BIT,
		CLEANUP
	} state_t;
	
	state_t state = IDLE;
	logic [12:0] clock_count = 0;
	logic [2:0]  bit_index	 = 0;
	logic [7:0]	 data_copy	 = 0; // Latch the data so it doesnt change mid-send
	
	always_ff @(posedge clk) begin
		case (state)
			IDLE: begin
				tx_serial 	<= 1; // Drive High (Idle)
				tx_busy 	 	<= 0;
				clock_count	<= 0;
				bit_index	<= 0;
				
				if (tx_start == 1) begin
					state			<= START_BIT;
					tx_busy		<= 1;
					data_copy	<= tx_byte; // Save the data
				end
			end
			
			START_BIT: begin
				tx_serial <= 0;
				
				if (clock_count < CLKS_PER_BIT - 1) begin
					clock_count <= clock_count + 1;
				end else begin
					clock_count <= 0;
					state 		<= DATA_BITS;
				end
			end
			
			DATA_BITS: begin
				tx_serial <= data_copy[bit_index]; // Send current bit
				
				if (clock_count < CLKS_PER_BIT - 1) begin
					clock_count <= clock_count + 1;
				end else begin
					clock_count <= 0;
					if (bit_index < 7) begin
						bit_index <= bit_index + 1;
					end else begin
						bit_index <= 0;
						state <= STOP_BIT;
					end
				end
			end
			
			STOP_BIT: begin
				tx_serial <= 1;
				
				if (clock_count < CLKS_PER_BIT - 1) begin
					clock_count <= clock_count + 1;
				end else begin
					state <= CLEANUP;
				end
			end
			
			CLEANUP: begin
				tx_busy <= 0;
				state <= IDLE;
			end
			
			default: state <= IDLE;
		endcase
	end

endmodule
