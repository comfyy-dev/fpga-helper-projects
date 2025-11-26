module SevenSeg_Decoder (
	input logic [3:0] num,
	output logic [7:0] segments
);

	always_comb begin
		case (num)
			4'd0: segments = 8'b11000000; // 0
			4'd1: segments = 8'b11111001; // 1
			4'd2: segments = 8'b10100100; // 2
			4'd3: segments = 8'b10110000; // 3
			4'd4: segments = 8'b10011001; // 4
			4'd5: segments = 8'b10010010; // 5
			4'd6: segments = 8'b10000010; // 6
			4'd7: segments = 8'b11111000; // 7
			4'd8: segments = 8'b10000000; // 8
			4'd9: segments = 8'b10010000; // 9
			// HEX ADDITIONS
            4'd10: segments = 8'b10001000; // A
            4'd11: segments = 8'b10000011; // B
            4'd12: segments = 8'b11000110; // C
            4'd13: segments = 8'b10100001; // D
            4'd14: segments = 8'b10000110; // E
            4'd15: segments = 8'b10001110; // F
			default: segments = 8'b11111111; // OFF
		endcase
	end
endmodule
	