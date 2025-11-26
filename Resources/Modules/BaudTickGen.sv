module BaudTicketGen (
	input logic clk,
	output logic tick // Pulses high once per bit-time (9600 baud)
);

	//50MHz / 9600 = 5208.333 -> 5208
	localparam LIMIT = 5208;
	
	logic [12:0] counter = 0; // 13 bits needed to hold 5208
	
	always_ff @(posedge clk) begin
		if (counter >= LIMIT - 1) begin
			counter <= 0;
			tick <= 1;
		end else begin
			counter <= counter + 1;
			tick <= 0;
		end
	end
	
endmodule
