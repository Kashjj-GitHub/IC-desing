`timescale 1ns / 1ps

// ==============================================
// Módulo Top
// Proyecto: UART Receptor y Transmisor con visualización en display de 7 segmentos
// Autor: Kevin
//
// Descripción:
// - Recibe datos seriales UART desde el puerto RX.
// - Envía de vuelta (echo) el dato recibido por el transmisor UART TX.
// - Muestra el byte recibido en un display de 4 dígitos de 7 segmentos.
// - Usa el módulo UART_RX para recibir datos UART.
// - Usa el módulo UART_TX para transmitir los datos recibidos de vuelta.
// - Usa el módulo Binary_16_Bits_To_7_Segment_4_Digits_Display para mostrar datos binarios en display 7 segmentos multiplexado.
// ==============================================

module top(
    input        i_clk,            // Reloj del sistema (100 MHz típico en Basys3)
    input        i_UART_RX,        // Línea UART de recepción (Rx)
    output       o_UART_TX,        // Línea UART de transmisión (Tx)
    output [6:0] o_Segments,       // Salidas para los segmentos A-G del display (activos bajos)
    output [3:0] o_Anodes          // Control de ánodos para los 4 dígitos (activos bajos)
);

    // ==============================
    // Señales internas (wires)
    // ==============================
    wire    [6:0]  w_Segments;       // Señales para segmentos del display generadas por el driver
    wire    [3:0]  w_Anodes;         // Señales para ánodos generadas por el driver
    wire           w_RX_DV;          // Indica cuando un byte UART ha sido recibido correctamente
    wire    [7:0]  w_RX_Byte;        // Byte recibido vía UART
    wire    [15:0] w_Display_Data;   // Datos a mostrar en display (extendidos a 16 bits)
    wire           w_TX_Active;      // Indica que la transmisión está activa
    wire           w_TX_Serial;      // Línea serial de salida TX

    // ==================================================
    // Preparar datos para mostrar en el display
    // Solo se muestra el byte recibido (8 bits bajos)
    // Se rellenan 8 bits altos con ceros para completar 16 bits
    // ==================================================
    assign  w_Display_Data = {8'h00, w_RX_Byte};

    // ==================================================
    // Instancia del receptor UART
    // - Parámetro CLKS_PER_BIT = 868 para 115200 baudios con reloj a 100 MHz
    // ==================================================
    UART_RX #(.CLKS_PER_BIT(868)) UART_RX_Instance
    (
        .i_clk(i_clk),
        .i_RX_Serial(i_UART_RX),
        .o_RX_DV(w_RX_DV),
        .o_RX_Byte(w_RX_Byte)
    );

    // ==================================================
    // Instancia del transmisor UART
    // - Envía el byte recibido de vuelta (echo)
    // - i_Rst_L se conecta a 1 (reset desactivado)
    // ==================================================
    UART_TX #(.CLKS_PER_BIT(868)) UART_TX_Instance    
    (   
        .i_Rst_L(1'b1),             // Reset activo bajo desactivado (siempre habilitado)
        .i_clk(i_clk),      
        .i_TX_DV(w_RX_DV),          // Activa transmisión al recibir dato válido
        .i_TX_Byte(w_RX_Byte),      // Byte a transmitir (echo)
        .o_TX_Active(w_TX_Active),  // Indica transmisión activa
        .o_TX_Serial(w_TX_Serial),  // Línea serial TX
        .o_TX_Done()                // No se usa en este top
     );

    // Línea UART_TX queda en 1 cuando no está transmitiendo (idle)
    assign o_UART_TX = w_TX_Active ? w_TX_Serial : 1'b1;

    // ==================================================
    // Instancia del módulo display 7 segmentos multiplexado
    // Convierte el valor binario de 16 bits a señales para 4 dígitos hexadecimales
    // ==================================================
    Binary_16_Bits_To_7_Segment_4_Digits_Display
    (
        .i_clk(i_clk),
        .i_Binary_Num(w_Display_Data),
        .o_Segments(w_Segments),
        .o_Anodes(w_Anodes)
    );

    // ==================================================
    // Asignación de salidas al display
    // - Se invierten los segmentos porque los displays son activos bajos
    // - Ánodos se conectan directamente
    // ==================================================
    assign  o_Segments = ~w_Segments;
    assign  o_Anodes   = w_Anodes;

endmodule
