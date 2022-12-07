
//Bottom modules : CONV_1ch_dw1 + Relu + Maxpooling

`timescale 1ns / 1ps

module convlayer1 #(parameter I_BW = 16, CI = 1, CO = 3, O_CONV_BW = 20, O_BW = 16, IF_SIZE_CONV = 28, K_SIZE = 5, W_BW = 8, P_SIZE = 2)
  (
  clk, ce, global_rst_n, rst,
  i_fmap, i_weight,
  o_result,
  o_valid_max, o_end_max
  );

//assign port
input                                           clk, ce, global_rst_n, rst;
input signed      [CI*I_BW-1:0]                 i_fmap;
input signed      [(CO*K_SIZE*K_SIZE*W_BW)-1:0] i_weight;

output                                          o_valid_max;
output                                          o_end_max;
output signed     [CO*O_BW-1:0]                 o_result;
//assign inside signal
genvar i;
wire signed [K_SIZE*K_SIZE*W_BW-1:0] w_weight [0:CO-1];
wire signed [O_CONV_BW-1:0]               w_conv_result [0:CO-1];
wire signed [O_CONV_BW-1:0]                 w_add_bias_result [0:CO-1];
wire signed [O_BW-1:0]                 w_add_bias_trun_result [0:CO-1];
wire signed [O_BW-1:0]               w_o_relu[0:CO-1];
wire signed [O_BW-1:0]               w_o_max [0:CO-1];
//assign output signal
wire                          w_valid_conv [0:CO-1];
wire                          w_valid_max [0:CO-1];
wire                          w_end_max   [0:CO-1];

wire w_i_valid [0:CO-1];
generate
  for(i=0; i<CO; i=i+1)begin
    assign w_weight[i][K_SIZE*K_SIZE*W_BW-1:0] = i_weight[i*(K_SIZE*K_SIZE*W_BW) +: (K_SIZE*K_SIZE*W_BW)];
    (* DONT_TOUCH = "TRUE" *) conv_1ch_dw1 #(.I_BW(I_BW),.O_BW(O_BW),.O_CONV_BW(O_CONV_BW),.IF_SIZE_CONV(IF_SIZE_CONV),.K_SIZE(K_SIZE),.W_BW(W_BW)) u_conv_1ch_dw1(
          .clk                          (clk),
          .ce                           (ce),
          .global_rst_n                   (global_rst_n),
          .rst                          (rst),
          .i_fmap                       (i_fmap),
          .i_weight                     (w_weight[i]),
          .o_conv_result                (w_conv_result[i]),
          .o_valid_conv                 (w_valid_conv[i])
        );
       assign w_add_bias_trun_result[i] = w_conv_result[i][O_CONV_BW-1:O_CONV_BW-O_BW];
    (* DONT_TOUCH = "TRUE" *) ReLU #(.BIT_WIDTH(O_BW)) u_relu(
      .clk(clk), .global_rst_n(global_rst_n), .rst(rst),
      .ce(w_valid_conv[i]),
      .i_data(w_add_bias_trun_result[i]),
      .o_data(w_o_relu[i]),
      .o_ce(w_i_valid[i])
    );
    (* DONT_TOUCH = "TRUE" *) maxpool1 #(.BW(O_BW),.P_SIZE(P_SIZE),.IF_SIZE(IF_SIZE_CONV-K_SIZE+1)) u_maxpool1 (
		.clk(clk), 
		.ce(w_i_valid[i]), 
		.global_rst_n(global_rst_n),
    .rst(rst),
		.i_data(w_o_relu[i]), 
		.o_data(w_o_max[i]),
		.o_valid(w_valid_max[i]),
		.o_end(w_end_max[i])
	);
  //Output feature
    assign o_result[i*O_BW +: O_BW] = w_o_max[i];
  end
endgenerate
//Output signals
assign o_valid_max = w_valid_max[0];
assign o_end_max   = w_end_max[0];
//Output value for testbench

endmodule