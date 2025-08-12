`timescale 1ns / 1ps

module VGA_Sync_Pulses #(
                         parameter TOTAL_COLS  = 800,
                         parameter TOTAL_ROWS  = 525,
                         parameter ACTIVE_COLS = 640,
                         parameter ACTIVE_ROWS = 480               
                        )
(
 input  i_clk,  //Reloj de 25MHz
 output o_HSync,
 output o_VSync,
 output [9:0] o_Col_Count,
 output [9:0] o_Row_Count
);

reg [9:0] r_Col_Count = 0;
reg [9:0] r_Row_Count = 0;

assign o_Col_Count = r_Col_Count;
assign o_Row_Count = r_Row_Count;


always @(posedge i_clk)
  begin
    if (r_Col_Count == TOTAL_COLS-1)
      begin
        r_Col_Count <= 0;
        
        if (r_Row_Count == TOTAL_ROWS-1)
          r_Row_Count <= 0;
        else
          r_Row_Count <= r_Row_Count + 1;
      end
    else
      r_Col_Count <= r_Col_Count + 1;
  
  end

assign o_HSync = r_Col_Count < ACTIVE_COLS ? 1'b1 : 1'b0;
assign o_VSync = r_Row_Count < ACTIVE_ROWS ? 1'b1 : 1'b0;

endmodule