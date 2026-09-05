module RegSprites (
	input clk, rst, armazenar, 
	input [4:0] endereco,
	input [24:0] write,
	
	output [799:0] sprite
);

	reg [24:0] banco [0:31];

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i<=31; i = i+1) begin
				banco[i] <= 32'd0;
			end

		end
		else begin
			if (armazenar) begin
				banco[endereco] <= write;
			end
		end
	end

	genvar k;
	generate
		for (k=0; k<=31; k=k+1) begin: empacotar
			assign sprite[k*25 +: 25] = banco[k];
		end
	endgenerate

endmodule

module RegPoligonos (
	input clk, rst, armazenar, 
	input [2:0] endereco,
	input [31:0] write,
	
	output [255:0] poligono
);

	reg [31:0] banco [0:7];

	integer i;
	always @(posedge clk) begin
		if (rst) begin
				banco[0] <= {3'd0, 3'd0, 1'b0, 8'hE0, 8'd30,  9'd30};  // Retangulo
            banco[1] <= {3'd1, 3'd1, 1'b0, 8'h1C, 8'd30,  9'd100}; // Quadrado
            banco[2] <= {3'd2, 3'd2, 1'b0, 8'h03, 8'd30,  9'd170}; // Equilatero
            banco[3] <= {3'd3, 3'd3, 1'b0, 8'hFC, 8'd30,  9'd240}; // Isosceles
            banco[4] <= {3'd4, 3'd4, 1'b0, 8'hE3, 8'd120, 9'd50};  // Escaleno
			for (i = 5; i<=7; i = i+1) begin
				banco[i] <= 32'd0;
			end

		end
		else begin
			if (armazenar) begin
				banco[endereco] <= write;
			end
		end
	end

	genvar k;
	generate
		for (k=0; k<=7; k=k+1) begin: empacotar
			assign poligono[k*32 +: 32] = banco[k];
		end
	endgenerate

endmodule