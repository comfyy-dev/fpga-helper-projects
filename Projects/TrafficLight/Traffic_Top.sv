module Traffic_Top (
    input logic clk,
    input logic rst_n,
    output logic [2:0] traffic_leds, // Red, Yellow, Green LEDs
    output logic [7:0] seg,
    output logic [3:0] dig
);
    logic rst_n_clean;

    Debounce my_bouncer (
        .clk(clk),
        .button_in(rst_n),
        .button_out(rst_n_clean)
    );

    //Define our states with enums
    typedef enum logic [1:0] {
        S_RED,
        S_YELLOW,
        S_GREEN
    } state_t;

    state_t current_state, next_state;

    // One second timer 
    logic [31:0] timer_count = 0;
    logic tick_1s = 0;

    //50 MHz clock -> 50,000,000 ticks for 1 second
    always_ff @(posedge clk) begin
        if (timer_count >= 3) begin
            timer_count <= 0;
            tick_1s <= 1;
        end else begin
            timer_count <= timer_count + 1;
            tick_1s <= 0;
        end
    end

    // State machine and countdown logic
    logic [3:0] seconds_left;

    always_ff @(posedge clk or negedge rst_n_clean) begin
        if (!rst_n_clean) begin
            current_state <= S_RED;
            seconds_left <= 10;
        end else if (tick_1s) begin
            if (seconds_left == 0) begin
                case (current_state)
                    S_RED: begin
                        current_state <= S_GREEN;
                        seconds_left <= 5;
                    end

                    S_GREEN: begin
                        current_state <= S_YELLOW;
                        seconds_left <= 2;
                    end

                    S_YELLOW: begin
                        current_state <= S_RED;
                        seconds_left <= 10;
                    end
                endcase
            end else begin
            // keep counting down
                seconds_left <= seconds_left - 1;
            end
        end
    end

    // Outputs
    always_comb begin
        case (current_state)
            S_RED:      traffic_leds = 3'b011; // Red ON
            S_YELLOW:   traffic_leds = 3'b101; // Yellow ON
            S_GREEN:    traffic_leds = 3'b110; // Green ON
            default:    traffic_leds = 3'b111; // All OFF
        endcase
    end

    // Display driver
    logic [3:0] tens;
    logic [3:0] units;

    assign tens = (seconds_left >= 10) ? 1 : 0;
    assign units = (seconds_left >= 10) ? (seconds_left - 10) : seconds_left;

    Display_Driver my_display (
        .clk(clk),
        .in0(units),
        .in1(tens),
        .in2(4'd0),
        .in3(4'd0),
        .dig_sel(dig),
        .seg_out(seg)
    );

endmodule