module Display_Driver (
    input logic clk,
    input logic [3:0] in0, in1, in2, in3,
    output logic[3:0] dig_sel,
    output logic [7:0] seg_out
);

    logic [15:0] scan_counter = 0;
    logic [1:0] active_digit_index = 0;

    always_ff @(posedge clk) begin
        if (scan_counter >= 49999) begin
            scan_counter <= 0;
            active_digit_index <= active_digit_index + 1;
        end else begin
            scan_counter <= scan_counter + 1;
        end
    end

    logic [3:0] current_num;

    always_comb begin
        case (active_digit_index)
            2'd0: begin dig_sel = 4'b1110; current_num = in0; end
            2'd1: begin dig_sel = 4'b1101; current_num = in1; end
            2'd2: begin dig_sel = 4'b1011; current_num = in2; end
            2'd3: begin dig_sel = 4'b0111; current_num = in3; end
            default: begin dig_sel = 4'b1111; current_num = 0; end
        endcase
    end

    SevenSeg_Decoder my_decoder (
        .num(current_num),
        .segments(seg_out)
    );
endmodule