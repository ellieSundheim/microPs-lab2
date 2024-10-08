/* 
Name: Ellie Sundheim (esundheim@hmc.edu)
Date: 9/6/24
Purpose: This file contains the modules needed to multiplex and run 2 seven segement displays using one set of FPGA pins
*/

module top(input logic [3:0] s1, s2,
            output logic [4:0] led,
            output logic anode1_en, anode2_en,
            output logic [6:0] seg);

        // internal variables
		logic reset;
        logic clk;
        logic [3:0] sshow; //sshow = s on display

         // structural verilog, modules go here
        oscillator myOsc(clk);
        led_logic myLEDLogic(s1, s2, led);
        display_muxer #(16) myDisplayMuxer(clk, reset, s1, s2, anode1_en, anode2_en, sshow);
        seven_seg_disp mySevenSegDisp(sshow, seg);

endmodule

//displays sum of given digits
module led_logic(input logic [3:0] s1,
                 input logic [3:0] s2,
                 output logic [4:0] led);
        assign led = s1 + s2;
endmodule

// apparently humans can see flicker below 90Hz
// switching time of electronics is limited by ??
// to cut from 24 Mhz to 90 Hz, divide by 2^18 (roughly)
module display_muxer #(parameter NUM_CYCLES_ON_EXP = 18) //NUM_CYCLES_ON_EXP sets the number of clk cycles (2^N) that each side of the display is on for
                    (input logic clk,
					 input logic reset,
                     input logic [3:0] s1,s2,
                     output logic anode1_en, anode2_en,
                     output logic [3:0] sshow);

    logic [NUM_CYCLES_ON_EXP-1:0] counter;

    always_ff @(posedge clk, posedge reset)
		if (reset) counter <= 0;
        	else counter <= counter + 1;

    assign anode1_en = counter[NUM_CYCLES_ON_EXP-1];
	assign anode2_en = ~anode1_en;
    mux displayMux(anode1_en, s1, s2, sshow);

endmodule

//arbitrary width mux, defaults to 4
module mux #(parameter WIDTH = 4)
            (input logic select,
            input logic [WIDTH-1:0] s0, s1,
            output logic [WIDTH-1:0] out);

            always_comb
            case (select)
                1'b0: out = s0;
                1'b1: out = s1;
                default: out = 1'bx;
            endcase
endmodule

// internal oscillator
module oscillator(output logic clk);

	logic int_osc;
  
	// Internal high-speed oscillator (div 2'b01 makes it oscillate at 24Mhz)
	HSOSC #(.CLKHF_DIV(2'b01)) 
         hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

    assign clk = int_osc;
  
endmodule

// combinational logic for seven segment display
module seven_seg_disp(input logic[3:0] s,
					  output logic[6:0] seg);
	always_comb
	begin
		case(s[3:0])
			// select which segments need to light up based on which hex munber is input (seg = 7'b 6543210)
			4'b0000: seg = 7'b0111111;
			4'b0001: seg = 7'b0000110;
			4'b0010: seg = 7'b1011011;
			4'b0011: seg = 7'b1001111;
			4'b0100: seg = 7'b1100110;
			4'b0101: seg = 7'b1101101;
			4'b0110: seg = 7'b1111101;
			4'b0111: seg = 7'b0000111;
			
			4'b1000: seg = 7'b1111111;
			4'b1001: seg = 7'b1100111;
			4'b1010: seg = 7'b1110111;
			4'b1011: seg = 7'b1111100;
			4'b1100: seg = 7'b1011000;
			4'b1101: seg = 7'b1011110;
			4'b1110: seg = 7'b1111001;
			4'b1111: seg = 7'b1110001;
			default: seg = 7'b0000000;
		endcase
		//flip the bits because segment leds are actually active low
		seg = ~seg;
	end 

endmodule


// testbench settings
`timescale 1ns/1ns
`default_nettype none
`define N_TV 8

//testbench
module testbench();
	logic clk, reset;
	logic [3:0] s1, s2;
	logic anode1_en, anode1_en_expected;
	logic anode2_en, anode2_en_expected;
	logic [4:0] led, led_expected;
	logic [6:0] seg, seg_expected;
	logic [3:0] sshow;
	
	
	logic [31:0] vectornum, errors;
	logic [10:0] testvectors[10000:0]; // vectors of format s1[3:0]_s2[3:0]_seg[6:0]
	
	//instantiate DUT
	//top dut(s1, s2, led, anode1_en, seg);
	oscillator myOsc(clk);
	display_muxer #(18) myDispMux (clk, reset, s1, s2, anode1_en, anode2_en, sshow);
	
	
	//generate clock signal
/*
	always 
		begin
			clk = 1; #5;
			clk = 0; #5;
		end*/
		
		
	// At the start of the simulation:
	//  - Load the testvectors
	//  - Pulse the reset line (if applicable)
 initial
   begin
     // $readmemb("lab2\sim\led_logic_testvectors.tv", testvectors, 0, `N_TV - 1);
     vectornum = 0; errors = 0;
     reset = 0; #12; reset = 1; #27; reset = 0;
	 
     s1 = 4'b0001; s2 = 4'b0010; #10;
	 
   end
  
endmodule