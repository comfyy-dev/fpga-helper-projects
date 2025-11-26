module Breathing_Top (
    input logic clk,
    output logic [3:0] leds
);

    // 1. SLOW CLOCK ENABLE (Update brightness every 5ms or so)
    // 50MHz / 100,000 = 500Hz update rate for smoothness

    logic [19:0] timer_clk = 0;
    logic tick;

    always_ff @(posedge clk) begin
        if (timer_clk >= 800_000) begin //controls breathing speed 
            timer_clk <= 0;
            tick <= 1;
        end else begin
            timer_clk <= timer_clk + 1;
            tick <= 0;
        end
    end

    // 2. TRIANGLE WAVE LOGIC
    logic [7:0] brightness = 0;
    logic ramping_up = 1; // 1 -> increasing, 2 -> decreasing

    always_ff @(posedge clk) begin
        if (tick) begin
            if (ramping_up) begin
                if (brightness == 255) begin
                    ramping_up <= 0;
                    brightness <= 254;
                end else begin
                    brightness <= brightness + 1;
                end
            end else begin
                if (brightness == 0) begin
                    ramping_up <= 1;
                    brightness <= 1;
                end else begin
                    brightness <= brightness - 1;
                end
            end
        end
    end

    // 3. INSTANTIATE PWM DRIVER
    logic pwm_signal;
    
    PWM_Driver my_pwm (
        .clk(clk),
        .duty(brightness),
        .pwm_out(pwm_signal)
    );

    // 4. ASSIGN OUTPUTS
    // The LEDs on these boards are "Active Low" (0=ON).
    // Our PWM driver produces "Active High" logic (1=ON).
    // So we invert the signal with '~'.

    assign leds = {4{~pwm_signal}};

endmodule