`timescale 1ns / 1ps
module control #(parameter I_BW = 8, IF_SIZE = 28)
(
    clk, ce,
    rst, global_rst_n,

    o_ce, o_rst, o_load_data
);
input clk, ce, rst, global_rst_n;
output o_ce, o_rst, o_load_data;

reg r_load_weight;
reg r_ce_d;
reg r_ce_dd;
reg r_ce_ddd;
reg r_rst;

always @(posedge clk or negedge global_rst_n) begin
    if(!global_rst_n)begin
        r_ce_d <= 0;
        r_ce_dd <= 0;
        r_ce_ddd <= 0;
        r_rst <= 0;
        r_load_weight <= 0;
    end
    else if(r_rst==1) begin
        r_ce_d <= 0;
        r_ce_dd <= 0;
        r_ce_ddd <= 0;
        r_load_weight <= 0;
        r_rst <= 0;
    end
    else begin
        r_ce_d <= ce;
        r_ce_dd <= r_ce_d;
        r_ce_ddd <= r_ce_dd;
        r_rst <= rst;
        r_load_weight <= 1;
    end
end

assign o_ce = r_ce_ddd;
assign o_rst = r_rst;
assign o_load_data = r_load_weight;
endmodule