`timescale 1ns / 1ps

// ============================================================
// Módulo: UART Transmisor (UART_TX)
// Autor: Kevin
//
// Descripción:
// - Transmite un byte por UART en formato estándar:
//   1 bit de start (bajo), 8 bits de datos, 1 bit de stop (alto).
// - Controla la señal serial de salida o_TX_Serial.
// - Señaliza cuando la transmisión está activa (o_TX_Active).
// - Indica con o_TX_Done cuando termina de transmitir un byte.
//
// Parámetro:
// - CLKS_PER_BIT: número de ciclos de reloj por cada bit UART.
//   (Ej. para 115200 baudios con reloj de 100 MHz ≈ 868)
// ============================================================

module UART_TX
  #(parameter CLKS_PER_BIT = 868)
 (
  input       i_Rst_L,           // Reset activo bajo (reset asíncrono)
  input       i_clk,             // Reloj del sistema
  input       i_TX_DV,           // Data Valid: indica que hay un byte para transmitir
  input [7:0] i_TX_Byte,         // Byte a transmitir
  output reg  o_TX_Active,       // Indica que la transmisión está en curso
  output reg  o_TX_Serial,       // Línea serial de transmisión UART
  output reg  o_TX_Done          // Indica que la transmisión del byte terminó
  );
  
  // ============================================================
  // Estados de la máquina de estados principal
  // ============================================================
  localparam IDLE         = 2'b00;  // Esperando datos para transmitir
  localparam TX_START_BIT = 2'b01;  // Transmitiendo bit de start (0)
  localparam TX_DATA_BITS = 2'b10;  // Transmitiendo los 8 bits de datos
  localparam TX_STOP_BIT  = 2'b11;  // Transmitiendo bit de stop (1)
  
  reg [2:0] r_SM_Main;                        // Estado actual
  reg [($clog2(CLKS_PER_BIT)-1):0] r_Clock_Count;  // Cuenta ciclos para el timing del bit
  reg [2:0] r_Bit_Index;                      // Índice del bit que se transmite (0 a 7)
  reg [7:0] r_TX_Data;                        // Registro para almacenar el byte a transmitir
                     
  // ============================================================
  // Máquina de estados: transmisión secuencial por UART
  // ============================================================
  always @(posedge i_clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L) 
      begin
        // Reset asíncrono
        r_SM_Main     <= IDLE;
        o_TX_Serial   <= 1'b1;       // Línea idle UART siempre en alto
        o_TX_Active   <= 1'b0;
        o_TX_Done     <= 1'b0;
        r_Clock_Count <= 0;
        r_Bit_Index   <= 0;
      end
    else
      begin
        o_TX_Done <= 1'b0;           // Limpia flag de transmisión terminada cada ciclo
        
        case (r_SM_Main)
          
          // ----------------------------------------------------
          // Estado IDLE
          // - Espera a que i_TX_DV se active para comenzar la transmisión
          // - Línea serial en idle (alto)
          // ----------------------------------------------------
          IDLE:
            begin
              o_TX_Serial   <= 1'b1;    // Línea UART idle
              r_Clock_Count <= 0;
              r_Bit_Index   <= 0;
              
              if (i_TX_DV == 1'b1)
                begin
                  o_TX_Active <= 1'b1;   // Indica que empieza la transmisión
                  r_TX_Data   <= i_TX_Byte; // Guarda el byte a transmitir
                  r_SM_Main   <= TX_START_BIT; // Pasar a transmitir bit de start
                end
            end
          
          // ----------------------------------------------------
          // Estado TX_START_BIT
          // - Transmite bit de start (0) por un periodo completo
          // ----------------------------------------------------
          TX_START_BIT:
            begin
              o_TX_Serial <= 1'b0;      // Bit de start es 0
              
              if (r_Clock_Count < CLKS_PER_BIT - 1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main <= TX_START_BIT;
                end
              else
                begin
                  r_Clock_Count <= 0;
                  r_SM_Main <= TX_DATA_BITS; // Pasar a transmitir bits de datos
                end
            end
          
          // ----------------------------------------------------
          // Estado TX_DATA_BITS
          // - Transmite cada bit de datos del byte almacenado
          // - Cambia al siguiente bit tras el periodo de bit completo
          // ----------------------------------------------------
          TX_DATA_BITS:
            begin
              o_TX_Serial <= r_TX_Data[r_Bit_Index]; // Transmitir bit actual
              
              if (r_Clock_Count < CLKS_PER_BIT - 1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main <= TX_DATA_BITS;
                end
              else
                begin
                  r_Clock_Count <= 0;
                  
                  if (r_Bit_Index < 7)
                    begin
                      r_Bit_Index <= r_Bit_Index + 1; // Siguiente bit
                      r_SM_Main <= TX_DATA_BITS;
                    end
                  else
                    begin
                      r_Bit_Index <= 0;
                      r_SM_Main <= TX_STOP_BIT; // Pasar a bit de stop
                    end
                end
            end
          
          // ----------------------------------------------------
          // Estado TX_STOP_BIT
          // - Transmite bit de stop (1) por un periodo completo
          // - Señaliza que la transmisión ha terminado
          // ----------------------------------------------------
          TX_STOP_BIT:
            begin
              o_TX_Serial <= 1'b1;      // Bit de stop es 1
              
              if (r_Clock_Count < CLKS_PER_BIT - 1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main <= TX_STOP_BIT;
                end
              else
                begin
                  o_TX_Done <= 1'b1;     // Indica que terminó la transmisión
                  r_Clock_Count <= 0;
                  r_SM_Main <= IDLE;     // Volver a estado IDLE
                  o_TX_Active <= 1'b0;   // Desactiva señal de transmisión activa
                end
            end
          
          // ----------------------------------------------------
          // Estado por defecto para seguridad
          // ----------------------------------------------------
          default:
            r_SM_Main <= IDLE;
        endcase
      end
  end
           
endmodule
