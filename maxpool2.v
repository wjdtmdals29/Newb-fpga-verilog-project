`timescale 1ns / 1ps
module maxpool2 #(parameter BW = 16, P_SIZE = 2, IF_SIZE = 8)
(
    clk, global_rst_n, rst, ce,
    i_data, o_data,
    o_valid, o_end
);
    input clk, global_rst_n, rst, ce;
    input signed [BW-1:0]  i_data;
    output signed[BW-1:0]  o_data;
    output          o_valid;
    output          o_end;

    
    reg [P_SIZE-1:0]   r_count_2[0:P_SIZE-1];
    reg r_count_2_delay;
    reg [IF_SIZE:0]    r_count[0:1]  ;
    reg [IF_SIZE/2:0]  r_count_end;
    reg [P_SIZE-1:0]   r_count_row;
    reg signed [BW-1:0] r_store_in [0:P_SIZE-1];
    reg signed[BW-1:0] r_max_2_tmp2[0:IF_SIZE-1];
    //reg signed [BW-1:0] r_max_2_tmp;
    //reg [BW-1:0] r_max_2_tmp0;
    reg          r_rst[1:0];
    reg          r_valid;
    reg          r_end;
    reg  signed [BW-1:0] r_max1;
    wire signed [BW-1:0] w_max1;
    wire signed [BW-1:0] w_max2;
    integer n;
    integer i;
    integer k;

    reg out_clk[0:1];
    always @(posedge clk or negedge global_rst_n)
    begin
        r_rst[0] <= !global_rst_n||rst;
        r_rst[1] <= r_rst[0];
    
    if (!global_rst_n||rst)begin
    out_clk[0] <= 0;
    
    end
    else
       out_clk[0] <= ~out_clk[0];
       out_clk[1] <= out_clk[0];	
    end

    always@(posedge out_clk[0]) begin   
            if(r_end==1) begin
                r_end <= 0;
            end 
        if(r_rst[1]==1)begin
            r_count_2_delay <= 0;
            r_count[1] <= 0;
            r_count[0] <= 0;
            r_count_row <= 0;
            r_count_2[0] <= 0;
            r_count_2[1] <= 0;
            r_count_end <= 0;
            r_end <= 0;
            r_valid <= 0;
            for(k=0;k<IF_SIZE;k=k+1)begin
                r_max_2_tmp2[k] <= 0;
            end/*
    r_max_2_tmp2[0] <= 0;
    r_max_2_tmp2[1] <= 0;
    r_max_2_tmp2[2] <= 0;
    r_max_2_tmp2[3] <= 0;
    r_max_2_tmp2[4] <= 0;
    r_max_2_tmp2[5] <= 0;
    r_max_2_tmp2[6] <= 0;
    r_max_2_tmp2[7] <= 0;
    r_store_in[0] <= 0;
    r_store_in[1] <= 0;*/
    
        end
        r_max1 <= w_max1;
        if(r_count_end==IF_SIZE/2)begin
            r_end <= 1;
        end
        if(ce)  begin
            r_count[0] <= r_count[0]+1;
            r_count[1] <= r_count[0];
            r_count_2[1] <= r_count_2[0];
            r_count_2[0] <= r_count_2_delay;
            if(r_count_2_delay==0)begin
                r_count_2_delay <= 1;
            end
            else if(r_count_2_delay==1)begin
                r_count_2_delay <= 0;
            end


            
            for(i=0;i<IF_SIZE-1;i=i+1)begin
                r_max_2_tmp2[i+1] <= r_max_2_tmp2[i];
            end
            r_store_in[0] <= i_data;
            r_store_in[1] <= r_store_in[0];

            if(r_count_row == 0)begin
                    if(r_count_2[0] == 1) begin
                        r_max_2_tmp2[0] <= (r_store_in[0]>r_store_in[1]) ? r_store_in[0]:r_store_in[1];
                    if(r_count[1] == IF_SIZE-1)begin
                    r_count_row <= 1;
                    r_count[0] <= 1;
                    r_count[1] <= 0;
                    r_count_2[0] <= 0;
                    r_count_2[1] <= 0;
                    end
                end
                end
            if(r_count_row == 1)begin
                if(r_count_2[0] == 0) begin
                    r_valid <= 1;
                    if(r_count[0]==IF_SIZE-1)begin
                        r_count_end <= r_count_end+1;
                    end
                end
                else if(r_count_2[0] == 1) begin
                    r_valid <= 0;
                    if(r_count[1]==IF_SIZE-1)begin
                        r_count[0] <= 1;
                        r_count[1] <= 0;
                        r_count_2[0] <= 0;
                        r_count_2[1] <= 0;

                        r_count_row <= 0;
                    end
                    end
                end
            end
        end
    comparator2 #(.BW(BW)) u_comparator1
    (
        .i_data1(i_data),
        .i_data2(r_store_in[1]),
        .o_comp_max(w_max1)
    );
    comparator2 #(.BW(BW)) u_comparator2
    (
        .i_data1(w_max1),
        .i_data2(r_max_2_tmp2[IF_SIZE-1]),
        .o_comp_max(w_max2)
    );

    assign o_data = w_max2;
    assign o_valid = r_valid && out_clk[0] && ce && (~r_end);
    assign o_end = r_end;
endmodule