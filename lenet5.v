/*******************************************************************************
Author: SeungminJeong(newb)(Department of Electrical Engineering, Kwanwoon University, Nowon-gu, Seoul, South of Korea)
Associated Filename: lenet5.v
Purpose: verilog code to lenet5
Introduction : 28x28x1 input -> 5x5x3 conv1 -> 24x24x3 out -> Relu -> Max -> 14x14x3 -> 3x5x5x3 conv2 -> 8x8x3 out -> Relu -> Max -> 4x4x3 -> 48x10 FC layer -> 0-9 out
https://github.com/wjdtmdals29/Newb-fpga-verilog-project.git
*******************************************************************************/

`timescale 1ns / 1ps
module lenet5
(
	clk,  global_rst_n, ce,
	i_fmap,  
	o_result, o_end, o_ce, o_rst
);	

`include "global_param.vh"


	input clk;
	input ce;
	input global_rst_n;


	input signed  [I_SIZE1*I_SIZE1*I_BW1-1:0] i_fmap; 
	output [3:0]  o_result;
	output o_end;
	output o_ce;
	output o_rst;

	wire  signed [(CO1*K_SIZE*K_SIZE*W_BW)-1:0]    		w_weight1;
	wire  signed [(CO2*CI2*K_SIZE*K_SIZE*W_BW)-1:0] 	w_weight2;
	wire  signed [(CO3*CI3*I_SIZE3*I_SIZE3*W_BW)-1:0] 	w_weight3;
	wire  signed [CO3*B_BW-1:0]   				     	w_bias3;

	wire signed [CO1*O_BW1-1:0] w_result1;
	wire signed [CO1*O_BW1-1:0] w_result1_buf;
	wire w_valid_max1;
	wire w_valid_max1_buf;
	wire w_end_max1;
	wire signed [CO2*O_BW2-1:0]  w_result2;
	wire signed [CO2*O_BW2-1:0]  w_result2_buf;
	wire w_valid_max2;
	wire w_valid_max2_buf;
	wire w_end_max2;
	wire  [3:0]	w_result;
	reg r_ce;
	wire w_result_en;
	wire w_rst;

	always@(posedge clk or negedge global_rst_n)begin
		if(ce)begin

		end
	end

	always@(posedge clk) begin
		r_ce <= w_ce;
	end
	//Control clk, ce, load weight&bias value signal
	(* DONT_TOUCH = "TRUE" *) control #(.I_BW(I_BW1), .IF_SIZE(I_SIZE1)) u_control
	(
		.clk(clk), .ce(ce),
    	.rst(w_result_en), .global_rst_n(global_rst_n),

		.o_ce(w_ce), .o_rst(w_rst), .o_load_data(w_load_weight)
	);





	//////// Convolution layer 1 ////////
	// read conv weight
	(* DONT_TOUCH = "TRUE" *) rom #(.BW(W_BW),.SIZE(CO1*K_SIZE*K_SIZE),.FILE("conv1_weight.mem")) u_rom_conv1_weight
	(
		.clk(clk),.read_en(1'b1),.o_store_data(w_weight1)
	);
	// convolution layer1
	(* DONT_TOUCH = "TRUE" *) convlayer1 #(.I_BW(I_BW1),.K_SIZE(K_SIZE),.P_SIZE(P_SIZE),.W_BW(W_BW),.CI(CI1),.CO(CO1),.O_CONV_BW(O_CONV_BW1),.O_BW(O_BW1),.IF_SIZE_CONV(I_SIZE1)) u_convlayer1
	(
		.clk(clk), .ce(r_ce), .global_rst_n(global_rst_n), .rst(w_rst),
  		.i_fmap(i_fmap), .i_weight(w_weight1), //.i_bias(1'b0),
  		.o_valid_max(w_valid_max1), .o_end_max(w_end_max1),
  		.o_result(w_result1)
	);
	//The simulation results are the same whether you use all the buffer which under this code or not
	buffer #(.BW(CO1*O_BW1),.SIZE(I_SIZE2)) u_buffer_conv1_out
	(	
		.clk(clk), .global_rst_n(global_rst_n), .rst(rst),
    	.i_data(w_result1), .i_signal(w_valid_max1),
    	.o_data(w_result1_buf), .o_signal(w_valid_max1_buf)
	);



	//////// Convolution layer 2 ////////
	// read conv weight
	(* DONT_TOUCH = "TRUE" *) rom #(.BW(W_BW),.SIZE((CO2*CI2*K_SIZE*K_SIZE)),.FILE("conv2_weight.mem")) u_rom_conv2_dw_weight
	(
		.clk(clk),.read_en(w_load_weight),.o_store_data(w_weight2)
	);
	// convolution layer2
	(* DONT_TOUCH = "TRUE" *) convlayer2 #(.I_BW(I_BW2),.K_SIZE(K_SIZE),.P_SIZE(P_SIZE),.W_BW(W_BW),.CI(CI2),.CO(CO2),.O_CONV_BW(O_CONV_BW2),.O_BW(O_BW2),.IF_SIZE_CONV(I_SIZE2)) u_convlayer2
	(
		.clk(clk), .ce(w_valid_max1_buf), .global_rst_n(global_rst_n),.rst(w_rst),
  		.i_fmap(w_result1_buf), .i_weight(w_weight2), //.i_bias(1'b0),
		.o_valid_max(w_valid_max2), .o_end_max(w_end_max2),
  		.o_result(w_result2)
	);
	buffer #(.BW(CO2*O_BW2),.SIZE(I_SIZE3)) u_buffer_conv2_out
	(	
		.clk(clk), .global_rst_n(global_rst_n), .rst(rst),
    	.i_data(w_result2), .i_signal(w_valid_max2),
    	.o_data(w_result2_buf), .o_signal(w_valid_max2_buf)
	);


	//////// Fully connected layer ////////
	// read FC layer weight
	(* DONT_TOUCH = "TRUE" *) rom #(.BW(W_BW),.SIZE(CO3*CI3*I_SIZE3*I_SIZE3),.FILE("fc_weight.mem")) u_rom_conv3_weight
	(
		.clk(clk),.read_en(w_load_weight),.o_store_data(w_weight3)
	);
	// read FC layer bias
	(* DONT_TOUCH = "TRUE" *) rom #(.BW(B_BW),.SIZE(CO3),.FILE("fc_bias.mem")) u_rom_conv3_bias
	(
		.clk(clk),.read_en(w_load_weight),.o_store_data(w_bias3)
	);
	// fully connected layer(this module includes F.relu & comparator)
	(* DONT_TOUCH = "TRUE" *) fc #(.I_BW(I_BW3),.W_BW(W_BW),.B_BW(B_BW),.O_BW(O_BW3),.O_CONV_BW(O_CONV_BW3),.IF_SIZE(I_SIZE3),.CI(CI3),.CO(CO3)) u_fc
	(
		.clk(clk), .ce(w_valid_max2_buf), .global_rst_n(global_rst_n),.rst(w_rst),
    	.i_data(w_result2_buf), .i_weight(w_weight3), .i_bias(w_bias3),
    	.o_done(w_result_en), .o_data(w_result)
	);

	assign o_result = w_result;
	assign o_end = w_result_en;
	assign o_ce = w_ce;
	assign o_rst = w_rst;
     
endmodule
