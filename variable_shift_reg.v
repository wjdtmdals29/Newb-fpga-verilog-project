`timescale 1ns / 1ps

module variable_shift_reg #(parameter WIDTH = 8, parameter SIZE = 3) (
input clk,
input ce,
input global_rst_n,
input rst,
input [WIDTH-1:0] d,
output [WIDTH-1:0] out
);
reg [WIDTH-1:0] sr [SIZE-1:0];

generate
genvar i;
for(i=0;i<SIZE;i=i+1)
begin
    always@(posedge clk or negedge global_rst_n)
    begin
    if(ce)
    begin
        if(!global_rst_n||rst)
        begin
            sr[i] <= 'd0;
        end
        else
            if(i == 'd0)
            begin
                sr[i] <= d;
            end
            else
            begin
                sr[i] <= sr[i-1];
            end
        end
     else
     begin
        sr[i] <= sr[i];
     end
    end
end
assign out = sr[SIZE-1];

endgenerate
endmodule