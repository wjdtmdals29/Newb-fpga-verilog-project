
//Test Module : conv_1ch_dw + buffer + ReLU

`timescale 1ns / 1ps
module lenet5_tb;
`include "global_param.vh"
	// global Inputs
	reg clk;
	reg ce;
	reg global_rst_n;

	reg [I_BW1-1:0] i_fmap;
	reg [I_BW1-1:0] in_img [I_SIZE1*I_SIZE1*100-1:0];
	reg [10:0] pixel_count;
	reg [10:0] image_count;
	wire [3:0]  o_result;
	wire o_end;
	wire w_ce;
	wire w_rst;
	
	//assign w_bias = r_bias;
	parameter clkp = 2;

	lenet5 u_lenet5
	(
		.clk(clk),  .global_rst_n(global_rst_n), .ce(ce),
		.i_fmap(i_fmap),
		.o_result(o_result), .o_end(o_end)	,.o_ce(w_ce) ,.o_rst(w_rst)
	);
	always @(posedge clk) begin
		if(w_ce)begin
			if(pixel_count!=784) begin
		pixel_count <= pixel_count+1;	
		i_fmap <= in_img[784*image_count+pixel_count];
			end
			else begin
			pixel_count <= pixel_count;
			end
		end
		if(w_rst==1)begin
		pixel_count <= 0;
		image_count <= image_count + 1;
		end
		if(image_count==100)begin
			$stop;
		end
	end
	
	initial begin
		$readmemh("test_num_all_10timesl.mem", in_img); //read label pixel,, The numbers 0 through 9 are 10 each, a total of 100.
	end
	initial begin
		// Initialize Inputs
		image_count <= 0;
		pixel_count<=0;
		clk = 0;
		ce = 0;
		global_rst_n = 1;

		#1;
        clk = 0;
		ce = 0;
        global_rst_n =0;
        #1;
        global_rst_n =1;	
        #1;	
		ce=1;
	end
	
      always #(clkp/2) clk=~clk;      
endmodule