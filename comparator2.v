`timescale 1ns / 1ps

module comparator2 #(parameter BW = 16)
    (
    input [BW-1:0] i_data1,
    input [BW-1:0] i_data2,
    output [BW-1:0] o_comp_max
    );
    assign o_comp_max = (i_data1>i_data2) ? i_data1:i_data2;
endmodule