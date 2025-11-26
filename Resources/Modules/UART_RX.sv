module UART_RX (
	input logic clk,
	input logic rx_serial,			// Physical wire
	output logic [7:0] rx_byte,	// The captured byte
	output logic rx_dv				// Data Valid (Pulses high when byte is ready)
);
	// Parameters for 9600 Baud at 50MHz
	parameter CLKS_PER_BIT = 5208;
	
	// States
	typedef enum logic [2:0] {
		IDLE,
		START_BIT,
		DATA_BITS,
		STOP_BIT,
		CLEANUP
	} state_t;
	
	state_t state = IDLE;
	
	logic [12:0] clock_count = 0;	// Timer
	logic [2:0]	 bit_index	 = 0; // Which bit(0-7) are we on?
	logic [7:0]  temp_byte	 = 0; // Shift register
	
	always_ff @(posedge clk) begin
		case (state)
			// 1. IDLE: Wait for line to drop to 0
			IDLE: begin
				rx_dv <= 0;
				clock_count <= 0;
				bit_index <= 0;
				
				if (rx_serial == 0) begin // start bit detected!
					state <= START_BIT;
				end
			end
			
			// 2. START BIT: Wait half a bit-width to check if its real
			START_BIT: begin
				if (clock_count == (CLKS_PER_BIT / 2)) begin
					if (rx_serial == 0) begin // Still low? Good!
						clock_count <= 0;
						state <= DATA_BITS;
					end else begin
						state <= IDLE; // False alarm (noise)
					end
				end else begin
					clock_count <= clock_count + 1;
				end
			end
			
			// 3. DATA BITS: Sample 8 bits
			DATA_BITS: begin
				if (clock_count < CLKS_PER_BIT) begin
					clock_count <= clock_count + 1;
				end else begin
					// Time to sample!
					clock_count <= 0;
					temp_byte[bit_index] <= rx_serial; // Store the bit
					
					if (bit_index < 7) begin
						bit_index <= bit_index + 1;
					end else begin
						bit_index <= 0;
						state <= STOP_BIT;
					end
				end
			end
			
			// 4. STOP BIT:  Wait for the line to return high
			STOP_BIT: begin
				if (clock_count < CLKS_PER_BIT) begin
					clock_count <= clock_count + 1;
				end else begin
					rx_dv <= 1; 		// DONE! Tell the user data is ready
					rx_byte <= temp_byte;
					clock_count <= 0;
					state <= CLEANUP;
				end
			end
			
			// 5. CLEANUP: Just a single cycle reset
			CLEANUP: begin
				state <= IDLE;
				rx_dv <= 0;
			end
			
			default: state <= IDLE;
		endcase
	end

endmodule
					
					
					
					
					
					