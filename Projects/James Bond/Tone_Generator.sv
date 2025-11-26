module Tone_Generator (
    input logic clk, 
    input logic [19:0] tone_period,
    output logic buzzer_out
);

    logic [19:0] counter = 0;

    always_ff @(posedge clk) begin
        if (!tone_period) begin
            counter <= 0;
            buzzer_out <= 0;
        end else begin
            if (counter >= tone_period) begin
                counter <= 0;
                buzzer_out <= ~buzzer_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
endmodule

