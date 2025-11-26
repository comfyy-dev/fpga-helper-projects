module PinFinder (
	input logic pin_114,
	input logic pin_115,
	output logic led_1,
	output logic led_2
);

	assign led_1 = pin_114;
	assign led_2 = pin_115;
endmodule
