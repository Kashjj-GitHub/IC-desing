`timescale 1ns / 1ps

// ==============================================
// Top module
// Proyecto: UART Receiver con visualización en display 7 segmentos
// Autor: Kevin
// Descripción:
// - Recibe datos seriales por UART.
// - Muestra el dato recibido en los 4 dígitos del display de 7 segmentos.
// - Usa el módulo UART_RX para recibir datos.
// - Usa el módulo Binary_16_Bits_To_7_Segment_4_Digits_Display
//   para convertir datos binarios a dígitos en 7 segmentos.
// ==============================================

module top(
    input        i_clk,            // Reloj del sistema (100 MHz en Basys3)
    input        i_UART_RX,        // Entrada serial UART (desde USB/UART)
    output [6:0] o_Segments,       // Salidas de segmentos A-G del display (activos bajos)
    output [3:0] o_Anodes          // Control de ánodos para los 4 dígitos (activos bajos)
);

    // ==============================
    // Wires de interconexión
    // ==============================
    wire    [6:0]  w_Segments;       // Segmentos generados por el driver del display
    wire    [3:0]  w_Anodes;         // Anodos generados por el driver del display
    wire           w_RX_DV;          // Señal de Data Valid del receptor UART
    wire    [7:0]  w_RX_Byte;        // Byte recibido por UART
    wire    [15:0] w_Display_Data;   // Dato binario de 16 bits para mostrar en el display

    // ==================================================
    // Asignar byte recibido al display
    // - Usamos solo los 8 bits menos significativos.
    // - Los bits altos se dejan en cero para el display.
    // ==================================================
    assign  w_Display_Data = {8'h00, w_RX_Byte};

    // ==================================================
    // Instancia del módulo UART_RX
    // - CLKS_PER_BIT = 868 para 115200 baudios con reloj de 100 MHz.
    // ==================================================
    UART_RX #(.CLKS_PER_BIT(868)) UART_RX_Instance
    (
        .i_clk(i_clk),
        .i_RX_Serial(i_UART_RX),
        .o_RX_DV(w_RX_DV),
        .o_RX_Byte(w_RX_Byte)
    );

    // ==================================================
    // Instancia del driver para display 7 segmentos
    // - Convierte un valor binario de 16 bits en 4 dígitos BCD
    // - Genera señales de segmentos y ánodos
    // ==================================================
    Binary_16_Bits_To_7_Segment_4_Digits_Display
    (
        .i_clk(i_clk),
        .i_Binary_Num(w_Display_Data),
        .o_Segments(w_Segments),
        .o_Anodes(w_Anodes)
    );

    // ==================================================
    // Asignación de salidas
    // - Inversión de segmentos (~) porque los displays son activos bajos.
    // ==================================================
    assign  o_Segments = ~w_Segments;
    assign  o_Anodes   = w_Anodes;

endmodule

