module Clock_Top (
    input  logic clk,
    input  logic rst_n,
	 input  logic rx_serial,
    output logic [7:0] seg,
    output logic [3:0] dig
);
    localparam start_cmd_s = 8'h53; // 's' was typed
    localparam start_cmd_S = 8'h73; // 'S' was typed
	 
	 // UART Receiver
	 logic [7:0] rx_byte;
	 logic rx_ready;
	 
	 UART_RX rx (
		.clk(clk),
		.rx_serial(rx_serial),
		.rx_byte(rx_byte),
		.rx_dv(rx_ready)
	);
	
	// CMD Parser State Machine
	typedef enum logic [2:0] {
		IDLE,
        GET_MIN_10, // wait for tens of minutes
        GET_MIN_1,  // wait for ones of minutes
        GET_SEC_10, // wait for tens of seconds
        GET_SEC_1  // wait for ones of seconds
    } state_t;

    state_t state = IDLE;

    // Load signals (fired one by one)
    logic load_m10, load_m1, load_s10, load_s1;
    logic [3:0] parser_val;     // The number to extracted from UART
    // Since '0' is 0x30, we only need the lower 4 bits
    assign parser_val = rx_byte[3:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            if (rx_ready) begin
                if (rx_byte == start_cmd_s || rx_byte == start_cmd_S) begin
                    state <= GET_MIN_10;
                end
                else begin
                    case (state) 
                        IDLE: begin end
                        GET_MIN_10: state <= GET_MIN_1;
                        GET_MIN_1:  state <= GET_SEC_10;
                        GET_SEC_10: state <= GET_SEC_1;
                        GET_SEC_1:  state <= IDLE;
                        default:    state <= IDLE;
                    endcase
                end
            end
        end
    end

    logic is_restart_cmd;
    assign is_restart_cmd = (rx_byte == start_cmd_s || rx_byte == start_cmd_S);

    assign load_m10 = (state == GET_MIN_10 && rx_ready && !is_restart_cmd);
    assign load_m1  = (state == GET_MIN_1  && rx_ready && !is_restart_cmd);
    assign load_s10 = (state == GET_SEC_10 && rx_ready && !is_restart_cmd);
    assign load_s1  = (state == GET_SEC_1  && rx_ready && !is_restart_cmd);
    
    // 1. One second heartbeat (50Mhz -> 1Hz)
    logic [31:0] ticks;
    logic one_sec_pulse;

    always_ff @(posedge clk) begin
        if (ticks >= 49_999_999) begin
            ticks <= 0;
            one_sec_pulse <= 1;
        end else begin
            ticks <= ticks + 1;
            one_sec_pulse <= 0;
        end
    end

    // 2. Chain of counters
    logic [3:0] sec_ones, sec_tens, min_ones, min_tens;
    logic cry_1, cry_2, cry_3, cry_4;

    // Seconds (0-9)

    BCD_Counter c_sec_1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(one_sec_pulse),
        .load_enable(load_s1),
        .load_val(parser_val),
        .limit(4'd9),
        .count(sec_ones),
        .carry_out(cry_1)
    );

    BCD_Counter c_sec_10 (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(cry_1),
        .load_enable(load_s10),
        .load_val(parser_val),
        .limit(4'd5),
        .count(sec_tens),
        .carry_out(cry_2)
    );

    BCD_Counter c_min_1 (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(cry_2),
        .load_enable(load_m1),
        .load_val(parser_val),
        .limit(4'd9),
        .count(min_ones),
        .carry_out(cry_3)
    );

    BCD_Counter c_min_10 (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(cry_3),
        .load_enable(load_m10),
        .load_val(parser_val),
        .limit(4'd5),
        .count(min_tens),
        .carry_out(cry_4)
    );

    // 3. Display Driver
    // We will display MM.SS
    Display_Driver disp (
        .clk(clk),
        .in0(sec_ones),
        .in1(sec_tens),
        .in2(min_ones),
        .in3(min_tens),
        .dig_sel(dig),
        .seg_out(seg)
    );

endmodule