`timescale 1ns / 1ps
module ReLU #(parameter BIT_WIDTH = 32)(
    input clk, global_rst_n, rst, ce,
    input [BIT_WIDTH-1:0] i_data,
    output [BIT_WIDTH-1:0] o_data,
    output o_ce
    );
    reg [BIT_WIDTH-1:0] r_o_data;
    reg r_ce;
    always @(posedge clk or negedge global_rst_n) begin
      if(!global_rst_n||rst)begin
        r_o_data <= 0;
        r_ce <= 0;
      end
      else begin
        if(ce) begin
        r_o_data <= (i_data[BIT_WIDTH-1] == 1) ? 0 : i_data;
        r_ce <= ce;
        end
        else begin
        r_o_data <= 0;
        r_ce <= 0;
        end
      end
    end
assign o_data = r_o_data;
assign o_ce = r_ce;
endmodule
