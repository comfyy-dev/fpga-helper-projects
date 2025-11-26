module Chat_Server (
	input	logic clk,
	input logic rst_n,			// Button key0 (Send message)
	input logic rx_serial,		// UART_RX
	output logic tx_serial,		// UART_TX
	output logic [7:0] seg,		// Debug display
	output logic [3:0] dig
);

	// --- 1. Signals & Modules ---
    
	// UART Signals
	logic [7:0] rx_byte;
	logic rx_ready;
	logic [7:0] tx_byte;
	logic tx_start;
	logic tx_busy;
 
	// RAM Signals
	logic [9:0] write_ptr = 0;		// Where to save next char
	logic [9:0] read_ptr = 0;		// Where to read next char
	logic [7:0] ram_data_out;
	logic write_enable;
	 
	// Debounce the send button
	logic send_cmd;
	Debounce btn_db (
		.clk(clk),
		.button_in(rst_n),
		.button_out(send_cmd)
	);
	
	// UART Modules
	UART_RX rx_mod (
		.clk(clk),
		.rx_serial(rx_serial),
		.rx_byte(rx_byte),
		.rx_dv(rx_ready)
	);
	
	UART_TX tx_mod (
		.clk(clk),
		.tx_start(tx_start),
		.tx_byte(tx_byte),
		.tx_serial(tx_serial),
		.tx_busy(tx_busy)
	);
	
	RamChip my_ram (
		.clk(clk),
		.write_enable(write_enable),
		.data_in(rx_byte),
		.write_addr(write_ptr),
		.read_addr(read_ptr),
		.data_out(ram_data_out)
	);
	
	// Debug Display shows the last character displayed
	logic [7:0] last_char = 0;
	
	Display_Driver disp (
		.clk(clk),
		.in0(last_char[3:0]),
		.in1(last_char[7:4]),
		.in2 (4'd0),
		.in3(4'd0),
		.dig_sel(dig),
		.seg_out(seg)
	);
	
	// --- 2. STATE MACHINE ---
	typedef enum logic [2:0] {
		TYPING,			// Listen to UART, write to RAM
		PREPARE_READ,	// Wait for 1 cycle for RAM to fetch data
		SEND_BYTE,		// Trigger UART_TX
		WAIT_BUSY_HIGH,// 
		WAIT_TX			// Wait for UART to finish
	} state_t;
	
	state_t state = TYPING;
	
	always_ff @(posedge clk) begin
		
		// DEFAULT VALUES
		write_enable <= 0;
		tx_start <= 0;
		
		case (state)
			
			// MODE 1: USER IS TYPING
			TYPING: begin
				// If button is pressed, start sending
				// Detect falling edge of button: 1 -> 0)
				// Actually, Debounce output is Level. Lets just check if Low.
				if (send_cmd == 0 && write_ptr > 0) begin
					state <= PREPARE_READ;
					read_ptr <= 0;
				end
				
				// IF UART Data comes in
				else if (rx_ready) begin
					write_enable <= 1; // Write to RAM
					write_ptr <= write_ptr + 1;
					last_char <= rx_byte;
				end
			end
			
			// MODE 2: FETCH FROM RAM
			PREPARE_READ: begin
				// RAM takes 1 clock cycle to update 'ram_data_out'
				// after we change 'read_ptr'. We just wait here
				state <= SEND_BYTE;
			end
			
			// MODE 3: START TRANSMISSION
			SEND_BYTE: begin
				tx_byte <= ram_data_out;
				tx_start <= 1;
				state <= WAIT_BUSY_HIGH;
			end
			
			// MODE 4: WAIT FOR UART TO CONFIRM IT IS ACTUALLY BUSy
			WAIT_BUSY_HIGH: begin
				tx_start <= 0;
				if (tx_busy == 1) begin
					state <= WAIT_TX;
				end
			end
			
			// MODE 5: WAIT FOR COMPLETION
			WAIT_TX: begin
				// We need to wait for 'tx_busy' to go High (started)
				// and then go low (finished).
				// Simplified: just wait for busy to be 0 (if we ensure it started).
				// Better check: The UART_TX module raises busy immediately.
				
				if (tx_busy == 0) begin
					// Byte sent! Move to next.
					read_ptr <= read_ptr + 1;
					
					// Check if we are done
					if (read_ptr == write_ptr) begin
						// If done sending everything
						write_ptr <= 0; // Clear buffer (reset)
						state <= TYPING;
					end else begin
						// Still more to send
						state <= PREPARE_READ;
					end
				end
			end
			
		endcase
	end

endmodule


		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		