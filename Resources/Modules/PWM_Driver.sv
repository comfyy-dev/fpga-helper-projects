module PWM_Driver (
    input logic clk,
    input logic [7:0] duty,
    output logic pwm_out
);

    // 1. The "Carrier" Counter
    // This determines the frequency of the PWM.
    // 8-bit counter = 0-255.
    // 50MHz / 256 ≈ 195 kHz (Very fast, invisible flickering) 

    logic [7:0] counter = 0;

    always_ff @(posedge clk) begin : Carrier
        counter <= counter + 1;
    end

    // 2. The Comparator
    // If duty is 0, output is always 0.
    // If duty is 128, output is 1 for half the time.
    // If duty is 255, output is 1 for almost all the time.

    always_comb begin : Comparator
        pwm_out = (counter < duty) ? 1'b1 : 1'b0;
    end

endmodule