module MotorBG (
	input clk,
	input [8:0] bg_x, //coordenada X
	input [7:0] bg_y, //coordenada Y
	input [8:0] scroll_x, //deslocamento horizontal da câmera
	input [7:0] scroll_y, //deslocamento vertical da câmera
	output [7:0] draw
);

	wire [9:0] soma_x = {1'b0, bg_x} + {1'b0, scroll_x};
	wire [8:0] x_final = (soma_x >= 10'd320) ? (soma_x - 10'd320) : soma_x[8:0];

	wire [8:0] soma_y = {1'b0, bg_y} + {1'b0, scroll_y};
	wire [7:0] y_final = (soma_y >= 9'd240)  ? (soma_y - 9'd240)  : soma_y[7:0];

	//fatiamento em coordenadas de blocos e pixels
	wire [5:0] coluna = x_final[8:3]; //coluna de 0 a 39
	wire [4:0] linha = y_final[7:3]; //linha de 0 a 29

	//endereço na grade de 1200 posições do mapa (Linha * 40 + Coluna)
	wire [10:0] tilemap_addr = (linha * 6'd40) + coluna;

	ram_tilemap tm (
		.clock (clk),
		.address (tilemap_addr),
		.data (8'd0),
		.wren (1'b0),
		.q (draw)
	);

endmodule