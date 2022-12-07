//global
parameter W_BW = 8;
parameter K_SIZE = 5;
parameter P_SIZE = 2;
parameter B_BW = 8;
//Conv layer 1 param
parameter I_BW1 = 8;
parameter O_BW1 = 16;
parameter O_CONV_BW1 = 21;
//parameter O_CONV_BW1 = 20;
parameter I_SIZE1 = 28;
parameter O_SIZE1 = 12; //28-5 + 1
parameter CI1 = 1;
parameter CO1 = 3;
//Conv layer 2 param
parameter I_BW2 = 16;
parameter O_BW2 = 16;
parameter O_CONV_BW2 = 24; 
//parameter O_CONV_BW2 = 28; 
parameter I_SIZE2 = 12; //O_SIZE1 / 2, pooling
parameter O_SIZE2 = 4;  //12-5 + 1
parameter CI2 = 3;
parameter CO2 = 3;
//fully connected layer
parameter I_BW3 = 16;
parameter O_BW3 = 16;
parameter O_CONV_BW3 = 26; 
parameter I_SIZE3 = 4;
parameter O_SIZE3 = 1;
parameter CI3 = 3;
parameter CO3 = 10;




  


