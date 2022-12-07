`timescale 1ns / 1ps
module maxpool1 #(parameter BW = 16, P_SIZE = 2, IF_SIZE = 28)
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
    reg [IF_SIZE:0]    r_count  ;
    reg [IF_SIZE/2:0]  r_count_end;
    reg [P_SIZE-1:0]   r_count_row;
    reg signed [BW-1:0] r_store_in [0:P_SIZE-1];
    reg signed[BW-1:0] r_max_2_tmp2[0:IF_SIZE-1];
    reg          r_ce0;
    //reg          r_ce1;
    reg          r_valid;
    reg          r_end;
    reg  signed [BW-1:0] r_max1;
    wire signed [BW-1:0] w_max1;
    wire signed [BW-1:0] w_max2;
    integer n;
    integer i;
    integer k;

    
    always @(posedge clk or negedge global_rst_n) begin
        r_max1 <= w_max1;
        r_ce0 <= ce;
        //r_ce1 <= r_ce0;
        if(r_end==1) begin
        r_end <= 0;
        end
        
    if (!global_rst_n||rst)begin
        r_count <= 0;
        r_count_row <= 0;
        r_count_2[0] <= 0;
        r_count_2[1] <= 0;
        r_count_end <= 0;
        r_end <= 1'b0;
        r_valid <= 1'b0;
        for(k=0;k<IF_SIZE;k=k+1)begin
        r_max_2_tmp2[k] <= 0;
        end
        /*r_max_2_tmp2[0] <= 0;
        r_max_2_tmp2[1] <= 0;
        r_max_2_tmp2[2] <= 0;
        r_max_2_tmp2[3] <= 0;
        r_max_2_tmp2[4] <= 0;
        r_max_2_tmp2[5] <= 0;
        r_max_2_tmp2[6] <= 0;
        r_max_2_tmp2[7] <= 0;
        r_max_2_tmp2[8] <= 0;
        r_max_2_tmp2[9] <= 0;
        r_max_2_tmp2[10] <= 0;
        r_max_2_tmp2[11] <= 0;
        r_max_2_tmp2[12] <= 0;
        r_max_2_tmp2[13] <= 0;
        r_max_2_tmp2[14] <= 0;
        r_max_2_tmp2[15] <= 0;
        r_max_2_tmp2[16] <= 0;
        r_max_2_tmp2[17] <= 0;
        r_max_2_tmp2[18] <= 0;
        r_max_2_tmp2[19] <= 0;
        r_max_2_tmp2[20] <= 0;
        r_max_2_tmp2[21] <= 0;
        r_max_2_tmp2[22] <= 0;
        r_max_2_tmp2[23] <= 0;
        r_store_in[0] <= 0;
        r_store_in[1] <= 0;*/
    end
    else begin
    
    if(r_count_end==IF_SIZE/2)begin
            r_end <= 1;
    end
    if((ce==0)&&(r_ce0==1))begin
        for(n=0;n<IF_SIZE-1;n=n+1)begin
        r_max_2_tmp2[0] <= r_max1;
        r_max_2_tmp2[n+1] <= r_max_2_tmp2[n];
        end
    end
    if(ce)  begin
            r_count <= r_count+1;
            r_count_2[1] <= r_count_2[0];
            if(r_count_2[0]==0)begin
                r_count_2[0] <= 1;
            end
            else if(r_count_2[0]==1)begin
                r_count_2[0] <= 0;
            end
   
            for(i=0;i<IF_SIZE-1;i=i+1)begin
                r_max_2_tmp2[i+1] <= r_max_2_tmp2[i];
            end
            r_store_in[0] <= i_data;
            r_store_in[1] <= r_store_in[0];

            if(r_count_row == 0)begin
                if(r_count_2[1] == 0) begin
                    if(r_count == IF_SIZE-1)begin
                    r_count_row <= 1;
                    r_count <= 0;
                    end
                end
                else if(r_count_2[1] == 1) begin
                    r_max_2_tmp2[0] <= (r_store_in[0]>r_store_in[1]) ? r_store_in[0]:r_store_in[1];
                end
            end
            if(r_count_row == 1)begin
                if(r_count_2[0] == 0) begin
                    r_valid <= 1;
                end
                else if(r_count_2[0] == 1) begin
                    r_valid <= 0;
                    if(r_count==IF_SIZE-1)begin
                        r_count_row <= 0;
                        r_count <= 0;
                        r_count_end <= r_count_end+1;
                    end
                end
            end
        end
    end
    end
    
    comparator2 #(.BW(BW)) u_comparator1
    (
        .i_data1(i_data),
        .i_data2(r_store_in[0]),
        .o_comp_max(w_max1)
    );
    comparator2 #(.BW(BW)) u_comparator2
    (
        .i_data1(w_max1),
        .i_data2(r_max_2_tmp2[IF_SIZE-2]),
        .o_comp_max(w_max2)
    );
  
    assign o_data = w_max2;
    assign o_valid = r_valid && (~r_end);
    assign o_end = r_end;
endmodule