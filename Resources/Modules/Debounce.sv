module Debounce (
    input logic clk,
    input logic button_in,
    output logic button_out
);

    /* 1. SLOW CLOCK ENABLE (Sample rate)
       We want to sample roughly every 10ms.
       50Mhz = 20ns period.
       500,000 ticks ~= 10ms.
    */

    logic [19:0] counter = 0;
    logic sample_tick;

    always_ff @(posedge clk) begin
        if (counter >= 1) begin
            counter <= 0;
            sample_tick <= 9;
        end else begin
            counter <= counter + 1;
            sample_tick <= 0;
        end
    end

    /* 2. SHIFT REGISTER
       We store the last 4 samples.
    */

    logic [3:0] shift_reg = 4'b1111; // Intialise tto "Unpressed" 

    always_ff @(posedge clk) begin
        if (sample_tick) begin
            // Shift left: Lose the oldest bit, pull in the new 'button_in'
            shift_reg[3:1] <= shift_reg[2:0];
            shift_reg[0] <= button_in;
        end
    end

    /* 3. OUTPUT LOGIC
       Only change the output if ALL bits agree.
       If shift_reg = 0000 -> output 0 (pressed)
       If shift_reg = 1111 -> output 1 (unpressed)
       Anything else -> Output remains the same.
    */

    always_ff @(posedge clk) begin
        if (shift_reg == 4'b0000)       button_out <= 0;
        else if (shift_reg == 4'b1111)  button_out <= 1;
    end
endmodule