`timescale 1ns/1ps // Define time unit: 1 nanosecond steps

module Traffic_tb; // No inputs or outputs! It's a self contained universe.

	// 1. SIGNALS
	// We need variables to connect to our DUT (Device Under Test)
	
	logic clk;
	logic rst_n;
	logic [2:0] leds;
	logic [7:0] seg;
	logic [3:0] dig;
	
	// 2. INSTANTIATE THE DUT (Device Under Test)
   // This puts your actual Traffic Light code into the virtual world
	
	Traffic_Top uut (
		.clk(clk),
		.rst_n(rst_n),
		.traffic_leds(leds),
		.seg(seg),
		.dig(dig)
	);
	
	// 3. CLOCK GENERATOR
   // This magic loop creates a 50MHz clock (Period = 20ns)
   // It toggles every 10ns.
	
	initial begin
		clk = 0;
		forever #10 clk = ~clk;
	end
	
	// 4. STIMULUS (The Script)
   // This block runs once at the start
	
	initial begin
		// Start with the reset held down
		rst_n = 0;
		
		// Wait for 100 ns
		#2000
		
		// Release reset (let the traffic light start)
		rst_n = 1;
		
		// Run the simulation for a specific amount of time
      // Since our traffic light takes SECONDS to change, and simulating
      // seconds takes a long time, we usually hack the timer in the main code
      // to be faster for simulation, or we just run this for a long time.
		
		$display("Simulation Started...");
		
		// Let it run for 2,000,000 ns (2ms) just to see it start up
		#2000000;
		$display("Simulation Finished.");
      $stop; // Pause simulation
	end

endmodule