module BCD_Counter (
    input  logic clk,
    input  logic rst_n,
    input  logic enable_in,     // "Tick" from the previous stage
    input  logic load_enable,   // Force value (for setting time)
    input  logic [3:0] load_val,
    input  logic [3:0] limit,   // Does this digit roll over at 9 or 5?
    output logic [3:0] count,
    output logic carry_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            carry_out <= 0;
        end else if (load_enable) begin
            count <= load_val;
            carry_out <= 0;
        end else if (enable_in) begin
            if (count == limit) begin
                count <= 0;
                carry_out <= 1; // Fire the trigger for the next digit!
            end else begin
                count <= count + 1;
                carry_out <= 0;
            end
        end else begin
            carry_out <= 0;
        end
    end

endmodule
