`timescale 1ns / 1ps

module conv_1ch_dw2 #(parameter I_BW = 16, O_CONV_BW = 28, O_BW = 16, IF_SIZE_CONV = 14, K_SIZE = 5, W_BW = 8)
  (
  clk, ce, global_rst_n, rst,
  i_fmap, i_weight,
  o_conv_result,
  o_valid_conv
  );
localparam s = 1;

input                                        clk, ce, global_rst_n,rst;
input signed      [I_BW-1:0]                 i_fmap;
input signed      [(K_SIZE*K_SIZE)*W_BW-1:0] i_weight;
output signed     [O_CONV_BW-1:0]                 o_conv_result;
output                                       o_valid_conv;

reg [O_BW-1:0] r_count, r_count2, r_count3, r_row_count;
reg            r_en1,r_en2,r_en3;

wire signed [O_CONV_BW-1:0] w_tmp [K_SIZE*K_SIZE+1:0];
wire signed [W_BW-1:0] w_weight [0:K_SIZE*K_SIZE-1];
wire signed [O_CONV_BW-1:0] w_conv_result;
reg signed [O_CONV_BW-1:0] r_conv_result;
//breaking our i_weights into separate variables. We are forced to do this because verilog does not allow us to pass multi-dimensional 
//arrays as parameters
//----------------------------------------------------------------------------------------------------------------------------------
generate
	genvar k;
	for(k=0;k<K_SIZE*K_SIZE;k=k+1)
	begin
        assign w_weight [k][W_BW-1:0] = i_weight[W_BW*k +: W_BW]; 		
	end	
endgenerate
//----------------------------------------------------------------------------------------------------------------------------------
assign w_tmp[0] = 0;


generate
genvar i;
  for(i = 0;i<K_SIZE*K_SIZE;i=i+1)
  begin: MAC
    if((i+1)%K_SIZE == 0)                       
    begin
      if(i==K_SIZE*K_SIZE-1)                       
      begin 
      mac #(.I_BW(I_BW),.W_BW(W_BW),.O_CONV_BW(O_CONV_BW)) u_mac(     
        .clk(clk),                      
        .ce(ce),                         
        .global_rst_n(global_rst_n),
        .rst(rst),               
        .a(i_fmap),                 
        .b(w_weight[i]),                   
        .c(w_tmp[i]),                    
        .p(w_conv_result)                      
        );
      end
      else
      begin
      wire signed [O_CONV_BW-1:0] w_tmp2;
      mac #(.I_BW(I_BW),.W_BW(W_BW),.O_CONV_BW(O_CONV_BW)) u_mac(                   
        .clk(clk), 
        .ce(ce), 
        .global_rst_n(global_rst_n),
        .rst(rst),
        .a(i_fmap), 
        .b(w_weight[i]), 
        .c(w_tmp[i]), 
        .p(w_tmp2) 
        );
      
      variable_shift_reg #(.WIDTH(O_CONV_BW),.SIZE(IF_SIZE_CONV-K_SIZE)) u_SR (
          .d(w_tmp2),                 
          .clk(clk),                
          .ce(ce),               
          .global_rst_n(global_rst_n),
          .rst(rst),          
          .out(w_tmp[i+1])             
          );
      end
    end
    else
    begin
    //(* use_dsp = "yes" *)               //this line is optional depending on tool behaviour
   mac #(.I_BW(I_BW),.W_BW(W_BW),.O_CONV_BW(O_CONV_BW)) u_mac2(                    
      .clk(clk), 
      .ce(ce),
      .global_rst_n(global_rst_n),
      .rst(rst),
      .a(i_fmap),
      .b(w_weight[i]),
      .c(w_tmp[i]), 
      .p(w_tmp[i+1])
      );
    end 
  end 
endgenerate

reg r_o_end_conv[0:2];
reg r_o_valid_conv[0:2];
//The following logic generates the 'o_valid_conv' and 'o_end_conv' output signals that tell us if the output is valid.
always@(posedge clk or negedge global_rst_n) 
begin
  if(!(global_rst_n)||rst)
  begin
    r_count <=0;                      //master r_counter: r_counts the clock cycles
    r_count2<=0;                      //r_counts the valid convolution outputs
    r_count3<=0;                      // r_counts the number of invalid onvolutions where the kernel wraps around the next row of inputs.
    r_row_count <= 0;                 //r_counts the number of rows of the output.  
    r_en1<=0;
    r_en2<=0;
    r_en3<=0;
    r_o_end_conv[0] <= 0;
    r_o_end_conv[1] <= 0;
    r_o_end_conv[2] <= 0;
    r_o_valid_conv[0] <= 0;
    r_o_valid_conv[1] <= 0;
    r_o_valid_conv[2] <= 0;
    r_conv_result<=0;
  end

  else begin
  if(r_o_end_conv[2]==0)begin
  if(ce)
  begin
    if(r_en1 && r_en2) 
  begin
    if(r_count2 == IF_SIZE_CONV-K_SIZE)
    begin
      r_count2 <= 0;
      r_en2 <= 0 ;
      r_row_count <= r_row_count + 1'b1;
    end
  end
    if(r_count == (K_SIZE-1)*IF_SIZE_CONV+K_SIZE-2)     
    begin
      r_en1 <= 1'b1;
      r_en2 <= 1'b1;
      r_count <= r_count+1'b1;
    end
    else
    begin 
      r_count<= r_count+1'b1;
    end
  
    if(r_en1 && r_en2) 
    begin
      if(r_count2 != IF_SIZE_CONV-K_SIZE)
      begin
      r_count2 <= r_count2 + 1'b1;
      end
    end
  
    if(~r_en2) 
    begin
      if(r_count3 == K_SIZE-2)
      begin
       r_count3<=0;
       r_en2 <= 1'b1;
      end
      else
      r_count3 <= r_count3 + 1'b1;
    end
    if((((r_count2 + 1) % s == 0) && (r_row_count % s == 0))||(r_count3 == K_SIZE-2)&&(r_row_count % s == 0)||(r_count == (K_SIZE-1)*IF_SIZE_CONV+K_SIZE-1))
    begin                                                                                                                        
     r_en3 <= 1;                                                                                                                             
    end
    else 
    r_en3 <= 0;
  end
  end
end
  r_o_end_conv[0] <= (r_count>= (IF_SIZE_CONV*IF_SIZE_CONV)) ? 1'b1 : 1'b0;
  r_o_end_conv[1] <= r_o_end_conv[0];
  r_o_end_conv[2] <= r_o_end_conv[1];
  r_o_valid_conv[0] <= (r_en1&&r_en2&&r_en3) && (~r_o_end_conv[1]);
  r_o_valid_conv[1] <= r_o_valid_conv[0];
  r_o_valid_conv[2] <= r_o_valid_conv[1];
  r_conv_result <= w_conv_result;
end

  assign o_conv_result = r_conv_result;
	assign o_valid_conv = r_o_valid_conv[2];

  
endmodule