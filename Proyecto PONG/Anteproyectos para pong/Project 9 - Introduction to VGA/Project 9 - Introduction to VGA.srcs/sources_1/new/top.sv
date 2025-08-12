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
    output [3:0] o_Anodes,         // Control de ánodos para los 4 dígitos (activos bajos)
    output       o_VGA_HSync,
    output       o_VGA_VSync,
    output [3:0] o_VGA_Red,
    output [3:0] o_VGA_Grn,
    output [3:0] o_VGA_Blu
);


    // VGA Constants to set Frame Size
    parameter c_VIDEO_WIDTH = 4;
    parameter c_TOTAL_COLS  = 800;
    parameter c_TOTAL_ROWS  = 525;
    parameter c_ACTIVE_COLS = 640;
    parameter c_ACTIVE_ROWS = 480;



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
    
    // Common VGA Signals
    wire w_clk_25MHz;
    
    wire w_HSync_Start;
    wire w_VSync_Start;
    wire w_HSync_TP;
    wire w_VSync_TP;
    wire [c_VIDEO_WIDTH-1:0] w_Red_Video_TP;
    wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_TP;
    wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_TP;
    
    wire w_HSync_Porch;
    wire w_VSync_Porch;
    wire [c_VIDEO_WIDTH-1:0] w_Red_Video_Porch;
    wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_Porch;
    wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_Porch;
    

    reg [3:0] r_TP_Index = 0;

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
    Binary_16_Bits_To_7_Segment_4_Digits_Display Binary_To_7_Segment_Display_Instance
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



    Clock_100MHz_to_25MHz Clock_100MHz_to_25MHz_Instance
    (
     .i_clk_100MHz(i_clk),
     .o_clk_25MHz(w_clk_25MHz)  
    );


    //////////////////////////////////////////////////////////////////
    // VGA Test Patterns
    //////////////////////////////////////////////////////////////////
    // Purpose: Register test pattern from UART when DV pulse is seen
    // Only least significant 4 bits are needed from whole byte.
    always @(posedge i_clk)
      begin
        if (w_RX_DV == 1'b1)
          r_TP_Index <= w_RX_Byte[3:0];
      end
     
    // Generates Sync Pulses to run VGA
    VGA_Sync_Pulses #(.TOTAL_COLS(c_TOTAL_COLS),
                      .TOTAL_ROWS(c_TOTAL_ROWS),
                      .ACTIVE_COLS(c_ACTIVE_COLS),
                      .ACTIVE_ROWS(c_ACTIVE_ROWS)) 
    VGA_Sync_Pulses_Inst 
    (.i_clk(w_clk_25MHz),
     .o_HSync(w_HSync_Start),
     .o_VSync(w_VSync_Start),
     .o_Col_Count(),
     .o_Row_Count()
    );
     
     
    // Drives Red/Grn/Blue video - Test Pattern 5 (Color Bars)
    Test_Pattern_Gen  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                        .TOTAL_COLS(c_TOTAL_COLS),
                        .TOTAL_ROWS(c_TOTAL_ROWS),
                        .ACTIVE_COLS(c_ACTIVE_COLS),
                        .ACTIVE_ROWS(c_ACTIVE_ROWS))
    Test_Pattern_Gen_Inst
     (.i_clk(w_clk_25MHz),
      .i_Pattern(r_TP_Index),
      .i_HSync(w_HSync_Start),
      .i_VSync(w_VSync_Start),
      .o_HSync(w_HSync_TP),
      .o_VSync(w_VSync_TP),
      .o_Red_Video(w_Red_Video_TP),
      .o_Grn_Video(w_Grn_Video_TP),
      .o_Blu_Video(w_Blu_Video_TP));
       
    VGA_Sync_Porch  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                      .TOTAL_COLS(c_TOTAL_COLS),
                      .TOTAL_ROWS(c_TOTAL_ROWS),
                      .ACTIVE_COLS(c_ACTIVE_COLS),
                      .ACTIVE_ROWS(c_ACTIVE_ROWS))
    VGA_Sync_Porch_Inst
     (.i_clk(w_clk_25MHz),
      .i_HSync(w_HSync_TP),
      .i_VSync(w_VSync_TP),
      .i_Red_Video(w_Red_Video_TP),
      .i_Grn_Video(w_Grn_Video_TP),
      .i_Blu_Video(w_Blu_Video_TP),
      .o_HSync(w_HSync_Porch),
      .o_VSync(w_VSync_Porch),
      .o_Red_Video(w_Red_Video_Porch),
      .o_Grn_Video(w_Grn_Video_Porch),
      .o_Blu_Video(w_Blu_Video_Porch));
         
    assign o_VGA_HSync = w_HSync_Porch;
    assign o_VGA_VSync = w_VSync_Porch;
         
    assign o_VGA_Red = w_Red_Video_Porch;
    assign o_VGA_Grn = w_Grn_Video_Porch;
    assign o_VGA_Blu = w_Blu_Video_Porch;


endmodule
