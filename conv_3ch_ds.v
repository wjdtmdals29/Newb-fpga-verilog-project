`timescale 1ns / 1ps

module conv_3ch_ds #(parameter I_BW = 16, CI = 3, O_CONV_BW = 28, O_BW = 24, IF_SIZE_CONV = 12, K_SIZE = 5, W_BW = 8)
  (
  clk, ce, global_rst_n, rst,
  i_fmap, i_weight,
  o_conv_result,
  o_valid_conv
  );

input clk, ce, global_rst_n, rst;
input signed [CI*I_BW-1:0]                 i_fmap;
input signed [(CI*K_SIZE*K_SIZE*W_BW)-1:0] i_weight;
output signed [O_BW-1:0]                   o_conv_result;
output o_valid_conv;

wire signed [K_SIZE*K_SIZE*W_BW-1:0] w_weight_dw      [0:CI-1];
wire signed [I_BW-1:0]               w_fmap        [0:CI-1];


wire signed [O_CONV_BW-1:0]                 w_dw_conv_result[0:CI-1];
wire                                 w_valid_conv  [0:CI-1];
wire                                 w_end_conv    [0:CI-1];
reg signed [O_CONV_BW:0]                 r_conv_sum;
reg r_valid;

always @(posedge clk or negedge global_rst_n) begin
  if((!global_rst_n)||rst) begin
      r_conv_sum <= 0;
      r_valid <= 0;
  end
  else begin
      r_conv_sum <= w_dw_conv_result[0] + w_dw_conv_result[1] + w_dw_conv_result[2];
      r_valid <= w_valid_conv[0];
  end
end


genvar i;
genvar n;
generate
  for(i=0; i<CI; i=i+1)begin
    assign w_weight_dw[i][K_SIZE*K_SIZE*W_BW-1:0] = i_weight[i*(K_SIZE*K_SIZE*W_BW) +: (K_SIZE*K_SIZE*W_BW)];
    assign w_fmap     [i][I_BW-1:0] = i_fmap[i*I_BW +: I_BW];
    
    conv_1ch_dw2 #(.I_BW(I_BW),.O_BW(O_BW),.O_CONV_BW(O_CONV_BW),.IF_SIZE_CONV(IF_SIZE_CONV),.K_SIZE(K_SIZE),.W_BW(W_BW)) u_conv_3ch_ds1(
          .clk                          (clk),
          .ce                           (ce),
          .global_rst_n                   (global_rst_n),
          .rst                          (rst),
          .i_fmap                       (w_fmap[i]),
          .i_weight                     (w_weight_dw[i]),
          .o_conv_result                (w_dw_conv_result[i]),
          .o_valid_conv                 (w_valid_conv[i])
        );
        
  end
endgenerate

assign o_conv_result = r_conv_sum[O_CONV_BW:O_CONV_BW-O_BW+1];
assign o_valid_conv = r_valid;
endmodule