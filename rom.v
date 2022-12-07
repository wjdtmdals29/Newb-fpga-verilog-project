`timescale 1ns / 1ps
module rom #(parameter BW = 8, SIZE = 26, FILE = "conv1_weight.txt")
(
	input clk,
	input read_en,
	output [BW*SIZE-1:0] o_store_data
);

reg signed [BW*SIZE-1:0] r_store_data;
reg signed [BW-1:0] r_weights [0:SIZE-1];
// simple way to read weights from memory
initial begin
	$readmemh(FILE, r_weights); // read 5x5 filter + 1 bias
end

reg[15:0] i;	// 2^16 = 65536
always @ (posedge clk) begin
	if (read_en) begin
		for (i = 0; i < SIZE; i = i+1) begin
			//read_out[BW*(i+1)-1 : BW*i] <= weights[i];
			r_store_data[i*BW +: BW] <= r_weights[i];
		end
	end
end
assign o_store_data = r_store_data;
endmodule