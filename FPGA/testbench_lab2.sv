`timescale 1ns/1ns
`default_nettype none
`define N_TV 8

module led_logic_tb();
	logic clk, reset;
	logic [3:0] s1, s2;
	logic [4:0] led, led_expected;
	
	
	logic [31:0] vectornum, errors;
	logic [10:0] testvectors[10000:0]; // vectors of format s1[3:0]_s2[3:0]_seg[6:0]
	
	//instantiate DUT
	led_logic dut(s1, s2, led);
	
	//generate clock signal
	always 
		begin
			clk = 1; #5;
			clk = 0; #5;
		end
		
		
	 // At the start of the simulation:
	//  - Load the testvectors
	//  - Pulse the reset line (if applicable)
 initial
   begin
     $readmemb("lab2\sim\led_logic_testvectors.tv", testvectors, 0, `N_TV - 1);
     vectornum = 0; errors = 0;
     reset = 1; #27; reset = 0;
	 
	 /*
	 without test vectors, just set up stuff here
	 e.g. s1 = 4'b0000; s2 = 4'b0001; #10;
	 */
	 s1 = 4'b0000; s2 = 4'b0001; #10;
	 
   end
  
endmodule
			