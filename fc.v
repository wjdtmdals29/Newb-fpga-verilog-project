`timescale 1ns / 1ps
module fc #(parameter I_BW = 32, W_BW = 16, B_BW = 32, O_BW = 32, O_CONV_BW = 32, IF_SIZE = 4, CI = 3, CO = 10 )
(
    clk, ce, global_rst_n, rst,
    i_data, i_weight, i_bias,
    o_done, o_data
);
input clk, ce, global_rst_n, rst;
input signed  [CI*I_BW-1:0]                i_data;
input signed  [CO*B_BW-1:0]                i_bias;
input signed  [CO*CI*IF_SIZE*IF_SIZE*W_BW-1:0] i_weight;
output signed [3:0]                        o_data;
output                                     o_done;

wire signed [I_BW-1:0]                      w_data      [0:CI-1];
wire signed [W_BW-1:0]                      w_weight    [0:(CO*CI*IF_SIZE*IF_SIZE)-1];
wire signed [B_BW-1:0]                      w_bias      [0:CO-1];
wire signed [O_CONV_BW-1:0]                    w_exp_bias      [0:CO-1];
reg  signed [O_CONV_BW-1:0]                      r_temp      [0:CO-1];
reg  signed [O_CONV_BW-1:0]                      r_temp_add_bias[0:CO-1];
reg  signed [O_BW-1:0]                      r_temp_add_bias_relu[0:CO-1];
reg  signed [IF_SIZE+1:0]    r_count;
reg  signed [4:0]            r_count_done;
reg                          r_store_end;
reg                          r_store_end_d;
reg [4:0]                    r_cnt_wei_addr;
reg  signed [O_BW-1:0]       r_temp_max5 [0:4];
reg r_result;
genvar o;
genvar i;
genvar w;
integer k;
integer t;
integer m;
generate
    for(i=0;i<CI;i=i+1)begin
    assign w_data[i][I_BW-1:0] = i_data[i*I_BW +: I_BW]; 
    end
    for(o=0;o<CO*CI*IF_SIZE*IF_SIZE;o=o+1) begin
    assign w_weight[o][W_BW-1:0] = i_weight[o*W_BW +: W_BW];
    end
    for(w=0;w<CO;w=w+1)begin
    assign w_bias [w][B_BW-1:0] = i_bias[w*B_BW +: B_BW];
    assign w_exp_bias[w][O_CONV_BW-1:0] = (w_bias[w][B_BW-1]==1) ? {20'b11111111111111111111, w_bias[w]} : {20'd0, w_bias[w]};
    end
endgenerate
    reg signed [O_BW-1:0] r_temp_max21;
    reg signed [O_BW-1:0] r_temp_max22;
    reg signed [O_BW-1:0] r_max;
    reg signed [O_BW-1:0] r_max_final;
    reg signed [0:3]  r_out_data;
    reg r_done;

    always @(posedge clk or negedge global_rst_n)begin
        if(r_done==1)begin
            r_done <= 0;
        end

        if((!global_rst_n)||rst)begin
        r_result <= 0;
        r_done  <= 0;
        r_count <= 0;
        r_count_done <= 0;
        r_store_end <= 0;
        r_store_end_d <= 0;
        r_temp_max5[0] <= 0;
        r_temp_max5[1] <= 0;
        r_temp_max5[2] <= 0;
        r_temp_max5[3] <= 0;
        r_temp_max5[4] <= 0;
        r_temp_max21 <= 0;
        r_temp_max22 <= 0;
        r_max <= 0;
        r_max_final <= 0;
        r_out_data <= 0;
        r_cnt_wei_addr <= 0;
        for(t=0;t<CO;t=t+1)begin
            r_temp[t] <= 0;
            r_temp_add_bias[t] <= 0;
            r_temp_add_bias_relu[t] <= 0;
        end
    end
        else begin

        if(ce) begin
            if(r_store_end==0)begin
            r_count <= r_count + 1;
                if(r_count != IF_SIZE*IF_SIZE) begin
                    r_cnt_wei_addr <= r_cnt_wei_addr + 1'b1;
                    
                    //if you implement 5x5x6 Convlayer 2,, then u use this code     16x6 = 96
                /*r_temp[0] <= r_temp[0] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*0)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*0)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*0)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*0)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*0)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*0)]);
                    r_temp[1] <= r_temp[1] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*1)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*1)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*1)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*1)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*1)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*1)]);
                    r_temp[2] <= r_temp[2] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*2)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*2)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*2)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*2)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*2)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*2)]);
                    r_temp[3] <= r_temp[3] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*3)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*3)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*3)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*3)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*3)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*3)]);
                    r_temp[4] <= r_temp[4] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*4)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*4)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*4)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*4)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*4)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*4)]);
                    r_temp[5] <= r_temp[5] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*5)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*5)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*5)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*5)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*5)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*5)]);
                    r_temp[6] <= r_temp[6] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*6)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*6)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*6)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*6)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*6)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*6)]);
                    r_temp[7] <= r_temp[7] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*7)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*7)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*7)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*7)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*7)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*7)]);
                    r_temp[8] <= r_temp[8] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*8)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*8)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*8)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*8)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*8)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*8)]);
                    r_temp[9] <= r_temp[9] + (w_data[0]*w_weight[r_cnt_wei_addr+(96*9)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(96*9)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(96*9)])+ (w_data[3]*w_weight[r_cnt_wei_addr+48+(96*9)]) +(w_data[4]*w_weight[r_cnt_wei_addr+64+(96*9)])+(w_data[5]*w_weight[r_cnt_wei_addr+80+(96*9)]);
                
                */
                //this code is for 5x5x3 Convlayer 2, 16x3 = 48
                    r_temp[0] <= r_temp[0] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*0)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*0)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*0)]);
                    r_temp[1] <= r_temp[1] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*1)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*1)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*1)]);
                    r_temp[2] <= r_temp[2] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*2)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*2)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*2)]);
                    r_temp[3] <= r_temp[3] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*3)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*3)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*3)]);
                    r_temp[4] <= r_temp[4] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*4)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*4)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*4)]);
                    r_temp[5] <= r_temp[5] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*5)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*5)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*5)]);
                    r_temp[6] <= r_temp[6] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*6)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*6)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*6)]);
                    r_temp[7] <= r_temp[7] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*7)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*7)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*7)]);
                    r_temp[8] <= r_temp[8] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*8)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*8)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*8)]);
                    r_temp[9] <= r_temp[9] + (w_data[0]*w_weight[r_cnt_wei_addr+(48*9)]) +(w_data[1]*w_weight[r_cnt_wei_addr+16+(48*9)])+(w_data[2]*w_weight[r_cnt_wei_addr+32+(48*9)]);
            
            end
        end
        end
        else if (r_count == IF_SIZE*IF_SIZE)begin
            if(r_store_end == 0)begin
            r_temp_add_bias[0] <= r_temp[0] + w_exp_bias[0];
            r_temp_add_bias[1] <= r_temp[1] + w_exp_bias[1];
            r_temp_add_bias[2] <= r_temp[2] + w_exp_bias[2];
            r_temp_add_bias[3] <= r_temp[3] + w_exp_bias[3];
            r_temp_add_bias[4] <= r_temp[4] + w_exp_bias[4];
            r_temp_add_bias[5] <= r_temp[5] + w_exp_bias[5];
            r_temp_add_bias[6] <= r_temp[6] + w_exp_bias[6];
            r_temp_add_bias[7] <= r_temp[7] + w_exp_bias[7];
            r_temp_add_bias[8] <= r_temp[8] + w_exp_bias[8];
            r_temp_add_bias[9] <= r_temp[9] + w_exp_bias[9];
            r_store_end <= 1;
            end
            //relu function to r_temp_add_bias
            if(r_store_end == 1)begin
            r_temp_add_bias_relu[0] <= (r_temp_add_bias[0][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[0][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[1] <= (r_temp_add_bias[1][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[1][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[2] <= (r_temp_add_bias[2][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[2][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[3] <= (r_temp_add_bias[3][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[3][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[4] <= (r_temp_add_bias[4][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[4][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[5] <= (r_temp_add_bias[5][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[5][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[6] <= (r_temp_add_bias[6][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[6][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[7] <= (r_temp_add_bias[7][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[7][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[8] <= (r_temp_add_bias[8][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[8][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_temp_add_bias_relu[9] <= (r_temp_add_bias[9][O_CONV_BW-1] == 1) ? 0 : r_temp_add_bias[9][O_CONV_BW-1:O_CONV_BW-O_BW];
            r_store_end_d <= r_store_end;
            end
        end

        if(r_store_end_d==1)begin
            r_count_done <= r_count_done+1;
            for(m=0;m<5;m=m+1)begin
                r_temp_max5[m] <= (r_temp_add_bias_relu[2*m] >= r_temp_add_bias_relu[2*m+1]) ? r_temp_add_bias_relu[2*m] : r_temp_add_bias_relu[2*m+1];
            end
            r_temp_max21 <= (r_temp_max5[0] > r_temp_max5[1]) ? r_temp_max5[0] :  r_temp_max5[1];
            r_temp_max22 <= (r_temp_max5[2] > r_temp_max5[3]) ? r_temp_max5[2] :  r_temp_max5[3];
            r_max        <= (r_temp_max21 > r_temp_max22) ? r_temp_max21 :  r_temp_max22;
            r_max_final  <= (r_temp_max5[4] > r_max) ? r_temp_max5[4] :  r_max;
        

        if(r_count_done == 4) begin
        r_done <= 1;
        r_result <= 1;
        if(r_max_final==r_temp_add_bias_relu[0])
            r_out_data <= 4'b0000;
        else if(r_max_final==r_temp_add_bias_relu[1])
            r_out_data <= 4'b0001;
        else if(r_max_final==r_temp_add_bias_relu[2])
            r_out_data <= 4'b0010;
        else if(r_max_final==r_temp_add_bias_relu[3])
            r_out_data <= 4'b0011;
        else if(r_max_final==r_temp_add_bias_relu[4])
            r_out_data <= 4'b0100;
        else if(r_max_final==r_temp_add_bias_relu[5])
            r_out_data <= 4'b0101;
        else if(r_max_final==r_temp_add_bias_relu[6])
            r_out_data <= 4'b0110;
        else if(r_max_final==r_temp_add_bias_relu[7])
            r_out_data <= 4'b0111;
        else if(r_max_final==r_temp_add_bias_relu[8])
            r_out_data <= 4'b1000;
        else if(r_max_final==r_temp_add_bias_relu[9])
            r_out_data <= 4'b1001;
        else
            r_out_data <= r_out_data;
        end
        end
    end
end
assign o_done = r_done;
assign o_data = r_out_data;


endmodule