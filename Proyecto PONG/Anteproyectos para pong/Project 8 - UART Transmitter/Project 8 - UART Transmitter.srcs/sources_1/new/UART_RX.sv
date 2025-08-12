`timescale 1ns / 1ps

// ============================================================
// Módulo: UART_RX
// Autor: Kevin
//
// Descripción:
// - Implementa un receptor UART.
// - Detecta el bit de inicio, lee 8 bits de datos
//   y verifica el bit de stop.
// - Genera o_RX_DV en alto durante un ciclo cuando
//   un byte se ha recibido correctamente.
//
// Parámetro:
// - CLKS_PER_BIT: número de ciclos de reloj por bit UART.
//   (Ej. para 115200 baudios con reloj de 100MHz ≈ 868)
// ============================================================

module UART_RX
    #(parameter CLKS_PER_BIT = 868)
    (
    input           i_clk,          // Reloj del sistema
    input           i_RX_Serial,    // Línea serie de recepción UART
    output          o_RX_DV,        // Indicador de dato válido (pulsado)
    output  [7:0]   o_RX_Byte       // Byte recibido
    );
    
    
    // ============================================================
    // Definición de estados de la máquina de estados.
    // ============================================================
    localparam   IDLE            = 3'b000;
    localparam   RX_START_BIT    = 3'b001;
    localparam   RX_DATA_BITS    = 3'b010;
    localparam   RX_STOP_BIT     = 3'b011;
    localparam   CLEANUP         = 3'b100;
    
    // ============================================================
    // Registros internos
    // ============================================================
    reg [9:0]  r_Clock_Count    = 0;      // Cuenta ciclos de reloj dentro de cada bit
    reg [2:0]  r_Bit_Index      = 0;      // Índice de bit (0 a 7)
    reg [7:0]  r_RX_Byte        = 0;      // Byte en recepción
    reg        r_RX_DV          = 0;      // Flag: dato recibido válido
    reg [2:0]  r_SM_Main        = 0;      // Estado actual de la máquina de estados
    
    
    // ============================================================
    // Máquina de estados principal
    // ============================================================
    always @(posedge i_clk)
    begin
        case (r_SM_Main)
            
            // ----------------------------------------------------
            // Estado IDLE
            // - Espera a que la línea baje (start bit detectado).
            // ----------------------------------------------------
            IDLE :
            begin
                r_Clock_Count   <= 0;
                r_Bit_Index     <= 0;
                r_RX_DV         <= 1'b0;
                
                if (i_RX_Serial == 1'b0)
                    r_SM_Main <= RX_START_BIT;  // Start bit detectado
                else
                    r_SM_Main <= IDLE;
            end
            
            // ----------------------------------------------------
            // Estado RX_START_BIT
            // - Verifica que el start bit permanezca bajo
            //   durante la mitad del período del bit.
            // - Esto ayuda a evitar errores por ruido.
            // ----------------------------------------------------
            RX_START_BIT :
            begin
                if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
                begin
                    if (i_RX_Serial == 1'b0)
                    begin
                        // Confirmado start bit, pasar a recibir datos
                        r_Clock_Count <= 0;
                        r_SM_Main     <= RX_DATA_BITS;
                    end
                    else
                        // Falsa detección, volver a IDLE
                        r_SM_Main <= IDLE;
                end
                else
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= RX_START_BIT;
                end
            end
            
            // ----------------------------------------------------
            // Estado RX_DATA_BITS
            // - Muestra cada bit de datos.
            // - Captura un bit cada CLKS_PER_BIT ciclos.
            // ----------------------------------------------------
            RX_DATA_BITS :
            begin
                if (r_Clock_Count < CLKS_PER_BIT - 1)
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= RX_DATA_BITS;
                end
                else
                begin
                    // Captura el bit recibido
                    r_RX_Byte[r_Bit_Index] <= i_RX_Serial;
                    r_Clock_Count          <= 0;
                    
                    if (r_Bit_Index < 7)
                    begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main   <= RX_DATA_BITS;
                    end
                    else
                    begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= RX_STOP_BIT;
                    end
                end
            end
            
            // ----------------------------------------------------
            // Estado RX_STOP_BIT
            // - Espera el bit de stop (debe ser alto).
            // - Genera el flag de dato válido.
            // ----------------------------------------------------
            RX_STOP_BIT :
            begin
                if (r_Clock_Count < CLKS_PER_BIT - 1)
                begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= RX_STOP_BIT;
                end
                else
                begin
                    r_RX_DV       <= 1'b1;      // Indicar que el byte es válido
                    r_SM_Main     <= CLEANUP;
                    r_Clock_Count <= 0;
                end
            end
            
            // ----------------------------------------------------
            // Estado CLEANUP
            // - Limpia flags y vuelve a IDLE.
            // ----------------------------------------------------
            CLEANUP :
            begin
                r_SM_Main <= IDLE;
                r_RX_DV   <= 1'b0;
            end
            
            // ----------------------------------------------------
            // Estado DEFAULT
            // - Seguridad en caso de estado inválido.
            // ----------------------------------------------------
            default :
                r_SM_Main <= IDLE;
            
        endcase
    end
    
    // ============================================================
    // Asignaciones de salida
    // ============================================================
    assign o_RX_DV   = r_RX_DV;
    assign o_RX_Byte = r_RX_Byte;
  
endmodule
