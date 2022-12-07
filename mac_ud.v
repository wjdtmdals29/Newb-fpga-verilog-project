`timescale 1ns / 1ps
//if you want to force using DSP, then use this MAC module, if not, use 'mac.v' module
(* use_dsp = "yes" *) module mac_ud #(parameter I_BW = 8, W_BW = 8, O_CONV_BW = 20)
    (
    input clk,global_rst_n,rst,ce,
    input signed [I_BW-1:0] a,
    input signed [W_BW-1:0] b,
    input signed [O_CONV_BW-1:0] c,
    output reg signed [O_CONV_BW-1:0] p
    );

always@(posedge clk or negedge global_rst_n)
 begin
    if(!global_rst_n||rst)
    begin
        p<=0;
    end
    else begin
        if(ce) begin
        p <= (a*b+c);
        end
        else begin
        p <= p;
        end
    end
 end
endmodule