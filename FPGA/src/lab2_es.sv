/* 
Name: Ellie Sundheim (esundheim@hmc.edu)
Date: 9/6/24
Purpose: This file contains the modules needed to multiplex and run 2 seven segement displays using one set of FPGA pins
*/

module top(input logic reset,
            input logic [3:0] s,
            input logic write1_en,
            output logic [4:0] led,
            output logic anode1_en,
            output logic [6:0] seg);

        // internal variables
        logic clk;
        logic [3:0] s1, s2, sshow; //sshow = s on display

         // structural verilog, modules go here
        oscillator myOsc(reset, clk);
        s_memory mySmemory(reset, clk, s, write1_en, s, s1, s2);
        led_logic myLEDLogic(s1, s2, led);
        display_muxer myDisplayMuxer(clk, s1, s2, anode1_en, sshow);
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
                     input logic [3:0] s1,s2,
                     output logic anode1_en,
                     output logic [3:0] sshow);

    logic [NUM_CYCLES_ON_EXP-1:0] counter;
    always_ff @(posedge clk)
        counter <= counter + 1;

    assign anode1_en = counter[NUM_CYCLES_ON_EXP-1];
    mux displayMux(anode1_en, s1, s2, sshow);

endmodule

module mux #(parameter WIDTH = 4)
            (input logic select,
            input logic [WIDTH-1:0] s0, s1,
            output logic [WIDTH-1:0] output);

            always_comb
            case (select):
                1'b0: output = s0;
                1'b1: output = s1;
                default: output = 1'bx;
            endcase
endmodule

// resettable, enabled flip flop
module flopren #(parameter WIDTH = 4)
                (input logic clk,
                input logic reset,
                input logic enable,
                input logic [WIDTH-1:0] d,
                output logic [WIDTH-1:0] q);

    always_ff @(posedge clk, posedge reset)
    begin
        if (reset) q <= 0;
        else if (enable) q <= d;
    end
endmodule


//flops to hold the previous values of each digit
module s_memory(input logic reset,
               input logic clk,
               input logic write1_en, 
               input logic [3:0] s,
               output logic [3:0] s1, s2);
        flopren dig1flop (clk, reset, write1_en, s, s1);
        flopren dig2flop (clk, reset, ~write1_en, s, s2);
endmodule

module oscillator(output logic clk);

	logic int_osc;
  
	// Internal high-speed oscillator (div 2'b01 makes it oscillate at 24Mhz)
	HSOSC #(.CLKHF_DIV(2'b01)) 
         hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));

    assign clk = int_osc;
  
endmodule

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