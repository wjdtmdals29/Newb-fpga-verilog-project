`timescale 1ns / 1ps
module buffer #(parameter BW = 16, SIZE = 32)
(
    clk, global_rst_n, rst,
    i_data, i_signal,
    o_data, o_signal
);
input clk, global_rst_n, rst;
input [BW-1:0] i_data;
input i_signal;
output [BW-1:0] o_data;
output o_signal;


reg [BW-1:0] r_data[0:SIZE-1];
reg          r_signal [0:SIZE-1];
integer i;
always@(posedge clk or negedge global_rst_n) begin
    if((!global_rst_n)||rst)begin
        for(i=0;i<SIZE;i=i+1)begin
        r_data[i] <= 0;
        r_signal[i] <= 0;
        end
    end
    else begin
        for(i=0;i<SIZE-1;i=i+1)begin
            r_data[i+1] <= r_data[i];
            r_data[0] <= i_data;
            r_signal[i+1] <= r_signal[i];
            r_signal[0] <= i_signal;
        end
    end
end
assign o_data = r_data[SIZE-1];
assign o_signal = r_signal[SIZE-1];
endmodule