module MotorSprites (
	input clk,

	input [8:0] next_x,
	input [7:0] next_y,
	
	//atributos
	input [799:0] sprites,

	output reg [7:0] draw
);

	//verifica bbox para colisao
	wire [31:0] colisao;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1) begin : check_box

			wire [31:0] sp = sprites[i*25 +: 25];

			wire [8:0] sx = sp[8:0];
			wire [7:0] sy = sp[16:9];
			wire show = sp[17];
			
			assign colisao[i] = show && (next_x >= sx) && (next_x < sx + 9'd16) && 
										(next_y >= sy) && (next_y < sy + 8'd16);
		end
	endgenerate

   // Prioridade Estática Fixa: Sprite 0 tem a maior prioridade
    reg [4:0] sprite_sel;
    reg hit;
    integer j;
    always @(*) begin
        hit = 1'b0;
        sprite_sel = 5'd0;
        for (j = 31; j >= 0; j = j - 1) begin
            if (colisao[j]) begin
                sprite_sel = j[4:0];
                hit = 1'b1;
            end
        end
    end
	
	//Atributos do sprite selecionado
	wire [31:0] sel_sp = sprites[sprite_sel*25 +: 25];
	wire [8:0] sel_sx = sel_sp[8:0];
	wire [7:0] sel_sy = sel_sp[16:9];
	wire sel_flip_h = sel_sp[18];
	wire sel_flip_v = sel_sp[19];

	//calculo do Offset do Pixel Interno com Flip
	wire [3:0] raw_dx = next_x - sel_sx;
	wire [3:0] raw_dy = next_y - sel_sy;

	wire [3:0] final_dx = sel_flip_h ? (4'd15 - raw_dx) : raw_dx;
	wire [3:0] final_dy = sel_flip_v ? (4'd15 - raw_dy) : raw_dy;

	//enderecamento da Memoria (8192 palavras: ID * 256 + dy * 16 + dx)
	wire [12:0] rom_addr = {sprite_sel, final_dy, final_dx};
	wire [7:0]  cor_pixel_rom;

	rom_sprites sprites_mem (
		.clock (clk),
		.address (rom_addr),
		.q (cor_pixel_rom)
);

	//sincronizacao de 1 ciclo para a saida
	reg hit_reg;
	always @(posedge clk) begin
	  hit_reg <= hit;
	end

	//selecao final da cor (Transparencia no indice 0) --- desenho
	always @(*) begin
	  if (hit_reg && (cor_pixel_rom != 8'd0))
			draw = cor_pixel_rom;
	  else
			draw = 8'd0;
	end

endmodule