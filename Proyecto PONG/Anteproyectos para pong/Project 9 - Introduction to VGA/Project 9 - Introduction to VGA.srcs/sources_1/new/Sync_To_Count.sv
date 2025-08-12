`timescale 1ns / 1ps

module Sync_To_Count #(
                       parameter TOTAL_COLS = 800,
                       parameter TOTAL_ROWS = 525
                      )
(
 input        i_clk,
 input        i_HSync,
 input        i_VSync,
 output       o_HSync,
 output       o_VSync,
 output [9:0] o_Col_Count,
 output [9:0] o_Row_Count
);

reg r_HSync;
reg r_VSync;
reg [9:0] r_Col_Count;
reg [9:0] r_Row_Count;


assign o_Col_Count = r_Col_Count;
assign o_Row_Count = r_Row_Count;
assign o_HSync     = r_HSync;
assign o_VSync     = r_VSync;


wire w_Frame_Start;

always @(posedge i_clk)
  begin
    r_HSync <= i_HSync;
    r_VSync <= i_VSync;
  end

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

assign w_Frame_Start = (~r_VSync & i_VSync);

endmodule
