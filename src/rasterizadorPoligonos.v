module rasterizadorPoligonos (
	input clk,

	input [8:0] next_x,
	input [7:0] next_y,

	input [255:0] poligono,

	output reg [7:0] draw
);

	//pertinência de Pixel para os 8 Polígonos
	wire signed [10:0] px = {2'b00, next_x};
	wire signed [10:0] py = {3'b000, next_y};

	wire [7:0] dentro;

	genvar i;
	generate
	  for (i = 0; i < 8; i = i + 1) begin : check_poly

	  	wire [31:0] poly = poligono [i*32 +: 32];

		wire [8:0] Ax_raw = poly[8:0];
		wire [7:0] Ay_raw = poly[16:9];
		wire [7:0] cor_raw = poly[24:17];
		wire show_raw = poly[25];
		wire [2:0] tipo_raw = poly[28:26];
			
		wire signed [10:0] ax = {2'b00, Ax_raw};
		wire signed [10:0] ay = {3'b000, Ay_raw};

		//vértices B e C calculados
		reg signed [10:0] bx, by, cx, cy;
		always @(*) begin
			case (tipo_raw)
				3'd2: begin // Equilátero
					bx = ax - 11'sd20; by = ay + 11'sd35;
					cx = ax + 11'sd20; cy = ay + 11'sd35;
				end
				3'd3: begin // Isósceles
					bx = ax - 11'sd10; by = ay + 11'sd45;
					cx = ax + 11'sd10; cy = ay + 11'sd45;
				end
				3'd4: begin // Escaleno
					bx = ax; by = ay + 11'sd30;
					cx = ax + 11'sd40; cy = ay + 11'sd30;
				end
				default: begin
					bx = ax; by = ay;
					cx = ax; cy = ay;
				end
			endcase
		end
					
		//equações de borda para triângulos
		wire signed [21:0] e1 = (bx - ax) * (py - ay) - (by - ay) * (px - ax);
		wire signed [21:0] e2 = (cx - bx) * (py - by) - (cy - by) * (px - bx);
		wire signed [21:0] e3 = (ax - cx) * (py - cy) - (ay - cy) * (px - cx);

		wire pixel_no_ret = (px >= ax) && (px <= ax + 11'sd40) &&  (py >= ay) && (py <= ay + 11'sd15);
		wire pixel_no_qua = (px >= ax) && (px <= ax + 11'sd30) && (py >= ay) && (py <= ay + 11'sd30);
		wire pixel_no_tri = (e1 <= 0) && (e2 <= 0) && (e3 <= 0);

		assign dentro[i] = show_raw && ((tipo_raw == 3'd0 && pixel_no_ret) || (tipo_raw == 3'd1 && pixel_no_qua) || 
		(tipo_raw >= 3'd2 && tipo_raw <= 3'd4 && pixel_no_tri));
	end
endgenerate

	//codificador de Prioridade e Saída
	reg [2:0] poly_sel;
	reg hit;
	integer j;
	always @(*) begin
		hit = 1'b0;
		poly_sel = 3'd0;
		for (j = 7; j >= 0; j = j - 1) begin
			if (dentro[j]) begin
					poly_sel = j[2:0];
					hit = 1'b1;
			end
		end
	end

	reg hit_reg;
	reg [7:0] cor_reg;
	always @(posedge clk) begin
		hit_reg <= hit;
		cor_reg <= poligono[poly_sel*32 + 17 +: 8];
	end

	always @(*) begin
		if (hit_reg && (cor_reg != 8'd0))
			draw = cor_reg;
		else
			draw = 8'd0;
	end

endmodule