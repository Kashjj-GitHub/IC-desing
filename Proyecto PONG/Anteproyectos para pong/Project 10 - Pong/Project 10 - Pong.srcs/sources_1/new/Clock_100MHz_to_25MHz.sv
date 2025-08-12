`timescale 1ns / 1ps

module Clock_100MHz_to_25MHz
(
 input  i_clk_100MHz,    // Reloj de entrada 100 MHz
 output o_clk_25MHz      // Reloj de salida 25 MHz (dividido por 4)
);

// Contador para dividir la frecuencia del reloj por 4
reg [1:0] r_Counter = 0;

// Registro que genera el reloj dividido
reg r_clk_25MHz = 0;

// Cada flanco positivo del reloj de 100 MHz,
// incrementa el contador. Al llegar a 2 ciclos,
// invierte el reloj de salida y reinicia contador.
always @(posedge i_clk_100MHz) 
  begin
    if (r_Counter < 1)
      r_Counter <= r_Counter + 1;
    else
      begin
        r_clk_25MHz <= ~r_clk_25MHz;
        r_Counter <= 0;
      end
  end

// Salida del reloj dividido
assign o_clk_25MHz = r_clk_25MHz; 

endmodule
