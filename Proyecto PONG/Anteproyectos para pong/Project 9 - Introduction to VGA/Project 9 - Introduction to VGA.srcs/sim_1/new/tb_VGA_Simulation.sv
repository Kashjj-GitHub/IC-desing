`timescale 1ns / 1ps

module tb_VGA_Simulation;

    // Parámetros VGA estándar
    parameter TOTAL_COLS  = 800;
    parameter TOTAL_ROWS  = 525;
    parameter ACTIVE_COLS = 640;
    parameter ACTIVE_ROWS = 480;

    // Relojes
    reg clk_100MHz = 0;
    wire clk_25MHz;

    // Señales VGA
    wire hsync;
    wire vsync;
    wire [9:0] col_count;
    wire [9:0] row_count;

    // Instanciar divisor de reloj (importante darle nombre a la instancia)
    Clock_100MHz_to_25MHz clk_div_inst (
        .i_clk_100MHz(clk_100MHz),
        .o_clk_25MHz(clk_25MHz)
    );

    // Instanciar módulo VGA Sync Pulses (con nombre)
    VGA_Sync_Pulses #(
        .TOTAL_COLS(TOTAL_COLS),
        .TOTAL_ROWS(TOTAL_ROWS),
        .ACTIVE_COLS(ACTIVE_COLS),
        .ACTIVE_ROWS(ACTIVE_ROWS)
    ) vga_sync_inst (
        .i_clk(clk_25MHz),
        .o_HSync(hsync),
        .o_VSync(vsync),
        .o_Col_Count(col_count),
        .o_Row_Count(row_count)
    );

    // Generador de reloj 100MHz: periodo 10ns
    always #5 clk_100MHz = ~clk_100MHz;

    initial begin
        // Mostrar valores en consola durante simulación
        $display("Tiempo(ns)\tcol_count\trow_count\thsync\tvsync");
        $monitor("%0d\t\t%0d\t\t%0d\t\t%b\t%b", 
                  $time, col_count, row_count, hsync, vsync);

        // Simular por 30ms (30_000_000 ns)
        #(30_000_000);

        $finish;
    end

endmodule
