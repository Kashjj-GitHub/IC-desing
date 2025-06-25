
`timescale 1ns / 1ps

module top(
    input   i_clk,
    input   i_Switch_1,
    output  o_Segment_A,
    output  o_Segment_B,
    output  o_Segment_C,
    output  o_Segment_D,
    output  o_Segment_E,
    output  o_Segment_F,
    output  o_Segment_G,
    
    output  o_Anode_0,
    output  o_Anode_1,
    output  o_Anode_2,
    output  o_Anode_3
    
    );

wire    w_Switch;    
reg     r_Switch_1 = 1'b0;
reg     [3:0] r_Count = 4'b0000;


wire    w_Segment_A;
wire    w_Segment_B;   
wire    w_Segment_C;   
wire    w_Segment_D;   
wire    w_Segment_E;   
wire    w_Segment_F;   
wire    w_Segment_G;   



Debounce_Switch
    (
    .i_clk(i_clk),
    .i_Switch(i_Switch_1),
    .o_Switch(w_Switch_1)
    );    


Binary_To_7Segment
    (
    .i_clk(i_clk),             
    .i_Binary_Num(r_Count),
    .o_Segment_A(w_Segment_A),      
    .o_Segment_B(w_Segment_B),      
    .o_Segment_C(w_Segment_C),      
    .o_Segment_D(w_Segment_D),      
    .o_Segment_E(w_Segment_E),      
    .o_Segment_F(w_Segment_F),      
    .o_Segment_G(w_Segment_G)       
    );  
      
      
always @(posedge i_clk)
   begin
        r_Switch_1 <= w_Switch_1;
        
    if (w_Switch_1 == 1'b0 && r_Switch_1 == 1'b1)
        begin
            if (r_Count==4'd9)
                r_Count <= 4'd0;
            else 
                r_Count <= r_Count + 1;
            end    
    end


assign  o_Segment_A = ~w_Segment_A;
assign  o_Segment_B = ~w_Segment_B;
assign  o_Segment_C = ~w_Segment_C;
assign  o_Segment_D = ~w_Segment_D;
assign  o_Segment_E = ~w_Segment_E;
assign  o_Segment_F = ~w_Segment_F;
assign  o_Segment_G = ~w_Segment_G;

assign  o_Anode_0 = 1'b0;
assign  o_Anode_1 = 1'b0;
assign  o_Anode_2 = 1'b0;
assign  o_Anode_3 = 1'b0;

    
endmodule
