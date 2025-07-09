`timescale 1ns / 1ps

// ============================================================
// Módulo: Binary_16_Bits_To_7_Segment_4_Digits_Display
// Autor: Kevin
//
// Descripción:
// - Recibe un número binario de 16 bits (i_Binary_Num)
// - Muestra su valor en 4 dígitos hexadecimales en displays
//   de 7 segmentos, multiplexados.
// - Controla el refresco de los dígitos con CLKS_PER_DIGIT
// ============================================================

module Binary_16_Bits_To_7_Segment_4_Digits_Display(
    input               i_clk,              // Reloj del sistema
    input       [15:0]  i_Binary_Num,       // Número binario de 16 bits a mostrar
    output      [6:0]   o_Segments,         // Segmentos [6]=A ... [0]=G
    output      [3:0]   o_Anodes            // Ánodos para los 4 dígitos (activos bajos)
    );
    
    // ============================================================
    // Parámetro que determina cuántos ciclos de reloj permanece
    // activo cada dígito antes de pasar al siguiente.
    // Ajustar para lograr la frecuencia de refresco deseada.
    // ============================================================
    parameter   CLKS_PER_DIGIT = 25000;
    
    // ============================================================
    // Registros internos
    // ============================================================
    reg [6:0]   r_Hex_Encoding  = 7'h00;      // Codificación de segmentos para el dígito actual
    reg [3:0]   r_Anodes        = 4'b1111;    // Control de los ánodos (activos bajos)
    reg [15:0]  r_Clock_Count   = 0;          // Contador para el multiplexado
    reg [3:0]   r_Digit         = 4'h0;       // Valor binario del dígito actual
    reg [2:0]   r_Digit_Index   = 0;          // Índice del dígito activo (0-3)
    
    // ============================================================
    // Proceso de multiplexado:
    // - Incrementa el índice de dígito cada CLKS_PER_DIGIT ciclos.
    // ============================================================
    always @(posedge i_clk)
    begin 
        if (r_Clock_Count < CLKS_PER_DIGIT - 1)
            r_Clock_Count <= r_Clock_Count + 1;
        else
        begin
            r_Clock_Count <= 0;
            if (r_Digit_Index < 3)
                r_Digit_Index <= r_Digit_Index + 1;
            else
                r_Digit_Index <= 0;
        end
    end
    
    // ============================================================
    // Selección del dígito a mostrar, según el índice.
    // Cada dígito toma 4 bits del número binario.
    // ============================================================
    always @(posedge i_clk)
    begin
        case (r_Digit_Index)
            2'd0:    r_Digit = i_Binary_Num[3:0];       // Dígito menos significativo
            2'd1:    r_Digit = i_Binary_Num[7:4];
            2'd2:    r_Digit = i_Binary_Num[11:8];
            2'd3:    r_Digit = i_Binary_Num[15:12];     // Dígito más significativo
            default: r_Digit = 4'h0;
        endcase
    end
    
    // ============================================================
    // Encendido de ánodos:
    // - Activa el ánodo correspondiente al dígito actual.
    // - Lógica activa baja (0 enciende el dígito).
    // ============================================================
    always @(posedge i_clk)
    begin
        case (r_Digit_Index)
            2'd0:    r_Anodes = 4'b1110;    // Enable digit 0
            2'd1:    r_Anodes = 4'b1101;    // Enable digit 1
            2'd2:    r_Anodes = 4'b1011;    // Enable digit 2
            2'd3:    r_Anodes = 4'b0111;    // Enable digit 3
            default: r_Anodes = 4'b1111;    // All off
        endcase
    end
    
    // ============================================================
    // Conversión binaria (4 bits) a segmentos de 7 segmentos.
    // Mapa de bits:
    // - [6] = A
    // - [5] = B
    // - [4] = C
    // - [3] = D
    // - [2] = E
    // - [1] = F
    // - [0] = G
    // ============================================================
    always @(posedge i_clk)
    begin
        case (r_Digit)
            4'b0000: r_Hex_Encoding = 7'h7E;   // 0
            4'b0001: r_Hex_Encoding = 7'h30;   // 1
            4'b0010: r_Hex_Encoding = 7'h6D;   // 2
            4'b0011: r_Hex_Encoding = 7'h79;   // 3
            4'b0100: r_Hex_Encoding = 7'h33;   // 4
            4'b0101: r_Hex_Encoding = 7'h5B;   // 5
            4'b0110: r_Hex_Encoding = 7'h5F;   // 6
            4'b0111: r_Hex_Encoding = 7'h70;   // 7
            4'b1000: r_Hex_Encoding = 7'h7F;   // 8
            4'b1001: r_Hex_Encoding = 7'h7B;   // 9
            4'b1010: r_Hex_Encoding = 7'h77;   // A
            4'b1011: r_Hex_Encoding = 7'h1F;   // B
            4'b1100: r_Hex_Encoding = 7'h4E;   // C
            4'b1101: r_Hex_Encoding = 7'h3D;   // D
            4'b1110: r_Hex_Encoding = 7'h4F;   // E
            4'b1111: r_Hex_Encoding = 7'h47;   // F
            default: r_Hex_Encoding = 7'h00;   // Apaga todos
        endcase
    end
   
    // ============================================================
    // Asignación de salidas
    // ============================================================
    assign o_Segments = r_Hex_Encoding;
    assign o_Anodes   = r_Anodes;
      
endmodule
