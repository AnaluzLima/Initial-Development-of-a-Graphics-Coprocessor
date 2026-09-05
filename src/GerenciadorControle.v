module GerenciadorControle (
	input clk25, clkD20, clkD24,

	input [3:0]  KEY,
	input [9:0]  SW,

	output [9:0] LEDR,

	//scroll do background
	output reg [8:0] scroll_x,
	output reg [7:0] scroll_y,

	//comandos dos sprites
	output reg cmd_sprite_en,
	output [24:0] cmd_sprite_data,

	//comandos rasterizador
	output reg cmd_poly_en,
	output [31:0] cmd_poly_data
);

	wire [1:0] editando = SW[9:8]; //define qual motor os botoes alteram

	//sprites
	wire [4:0] sel_sprite; 			// 0 a 31
	reg sel_show_s;                 //visibilidade
	reg flip_h; 					//espelha X
	reg flip_v;                     //espelha Y

	reg [8:0] pos_x_s [0:31];
	reg [7:0] pos_y_s [0:31];

	//poligonos
	wire [2:0] sel_poly; 			 // 0 a 7
	wire [2:0] sel_tipo_p = SW[5:3]; // 0=Ret, 1=Qua, 2=Eq, 3=Isos, 4=Esc
	wire sel_show_p = SW[6]; 		 // visibilidade
	wire [7:0] sel_cor_p  = 8'hE0; 	 // cor teste

	reg [8:0] pos_x_p [0:7];
	reg [7:0] pos_y_p [0:7];

	reg [4:0] figura;
	reg [2:0] motor;

	assign LEDR = {motor, 2'd0, figura};
	assign rst = ~KEY[3];
	
	reg [8:0] min_x_p, max_x_p;
   reg [7:0] min_y_p, max_y_p;

	always @(*) begin
	  case (sel_tipo_p)
			3'd0: begin // Retângulo (40x15)
				 min_x_p = 9'd0;  max_x_p = 9'd280;
				 min_y_p = 8'd0;  max_y_p = 8'd225;
			end
			3'd1: begin // Quadrado (30x30)
				 min_x_p = 9'd0;  max_x_p = 9'd290;
				 min_y_p = 8'd0;  max_y_p = 8'd210;
			end
			3'd2: begin // Equilátero (Bx = Ax - 20, Cx = Ax + 20, Altura 35)
				 min_x_p = 9'd20; max_x_p = 9'd300;
				 min_y_p = 8'd0;  max_y_p = 8'd205;
			end
			3'd3: begin // Isósceles (Bx = Ax - 10, Cx = Ax + 10, Altura 45)
				 min_x_p = 9'd10; max_x_p = 9'd310;
				 min_y_p = 8'd0;  max_y_p = 8'd195;
			end
			3'd4: begin // Escaleno (Bx = Ax, Cx = Ax + 40, Altura 30)
				 min_x_p = 9'd0;  max_x_p = 9'd280;
				 min_y_p = 8'd0;  max_y_p = 8'd210;
			end
			default: begin
				 min_x_p = 9'd0;  max_x_p = 9'd280;
				 min_y_p = 8'd0;  max_y_p = 8'd210;
			end
	  endcase
	end
	
	integer i;
	always @(posedge clkD20 or posedge rst) begin
	  if (rst) begin
			scroll_x <= 9'd0;
			scroll_y <= 8'd0;
			figura <= 5'd0;
			motor <= 3'd0;
			
			for (i = 0; i < 32; i = i + 1) begin
				pos_x_s[i] <= 9'd2 + (i * 9'd5);
				pos_y_s[i] <= 8'd40 + ((i % 6) * 8'd30);
			end
			
			pos_x_p[0] <= 9'd30;  pos_y_p[0] <= 8'd30;
			pos_x_p[1] <= 9'd100; pos_y_p[1] <= 8'd30;
			pos_x_p[2] <= 9'd170; pos_y_p[2] <= 8'd30;
			pos_x_p[3] <= 9'd240; pos_y_p[3] <= 8'd30;
			pos_x_p[4] <= 9'd50;  pos_y_p[4] <= 8'd120;
			for (i = 5; i < 8; i = i + 1) begin
				pos_x_p[i] <= 9'd120; pos_y_p[i] <= 8'd120;
			end

		end else begin
			
			case (editando)
				 //background
				 2'b01: begin
					motor <= 3'b001;
					if (SW[2:0] == 3'd2 && ~KEY[2]) scroll_x <= (scroll_x >= 9'd318) ? 9'd0 : scroll_x + 9'd2;
					if (SW[2:0] == 3'd1 && ~KEY[2]) scroll_x <= (scroll_x <= 9'd1) ? 9'd319 : scroll_x - 9'd2;
					if (SW[2:0] == 3'd4 && ~KEY[2]) scroll_y <= (scroll_y >= 8'd238) ? 8'd0 : scroll_y + 8'd2;
					if (SW[2:0] == 3'd3 && ~KEY[2]) scroll_y <= (scroll_y <= 8'd1) ? 8'd239 : scroll_y - 8'd2;
				 end

				 //sprites
				 2'b10: begin
					motor <= 3'b010;
					figura <= sel_sprite;
					if (SW[2:0] == 3'd2 && pos_x_s[sel_sprite] < 9'd304) pos_x_s[sel_sprite] <= pos_x_s[sel_sprite] + 9'd2;
					if (SW[2:0] == 3'd1 && pos_x_s[sel_sprite] > 9'd0)   pos_x_s[sel_sprite] <= pos_x_s[sel_sprite] - 9'd2;
					if (SW[2:0] == 3'd4 && pos_y_s[sel_sprite] < 8'd224) pos_y_s[sel_sprite] <= pos_y_s[sel_sprite] + 8'd2;
					if (SW[2:0] == 3'd3 && pos_y_s[sel_sprite] > 8'd0)   pos_y_s[sel_sprite] <= pos_y_s[sel_sprite] - 8'd2;
				 end

				 //poligonos
				 2'b11: begin
               motor <= 3'b100;
               figura <= {2'd0, sel_poly};
            
               if (SW[2:0] == 3'd2 && pos_x_p[sel_poly] < max_x_p) pos_x_p[sel_poly] <= pos_x_p[sel_poly] + 9'd2; 
               if (SW[2:0] == 3'd1 && pos_x_p[sel_poly] > min_x_p) pos_x_p[sel_poly] <= pos_x_p[sel_poly] - 9'd2;  
               if (SW[2:0] == 3'd4 && pos_y_p[sel_poly] < max_y_p) pos_y_p[sel_poly] <= pos_y_p[sel_poly] + 8'd2;   
               if (SW[2:0] == 3'd3 && pos_y_p[sel_poly] > min_y_p) pos_y_p[sel_poly] <= pos_y_p[sel_poly] - 8'd2;
            end

				default: begin
					motor <= 3'b000;
					figura <= 5'd0;
				 end
			endcase
	  end
	end

	always @(posedge clkD20) begin
		if(rst) begin
			sel_show_s <= 1'b0; 
			flip_h <= 1'b0; 
			flip_v <= 1'b0;
		end
		else begin
			case (SW[7:6])
				2'd0: begin
					sel_show_s <= 1'b0; 
					flip_h <= 1'b0;
					flip_v <= 1'b0;
				end 
				2'd1: begin
					sel_show_s <= 1'b1; 
					flip_h <= 1'b0; 
					flip_v <= 1'b0;
				end 
				2'd2: begin
					sel_show_s <= 1'b1; 
					flip_h <= 1'b1; 
					flip_v <= 1'b0;
				end 
				2'd3: begin
					sel_show_s <= 1'b1; 
					flip_h <= 1'b1; 
					flip_v <= 1'b1;
				end
				default: begin
					sel_show_s <= 1'b0; 
					flip_h <= 1'b0;
					flip_v <= 1'b0;
					end
			endcase
		end
		
	end

	Contador32 cont32(.clk(clkD24), .rst(rst), .aumentando(~KEY[0] && editando == 2'b10), .diminuindo(~KEY[1] && editando == 2'b10), . cont(sel_sprite));
	Contador8 cont8(.clk(clkD24), .rst(rst), .aumentando(~KEY[0] && editando == 2'b11), .diminuindo(~KEY[1] && editando == 2'b11), . cont(sel_poly));

	//comandos
	always @(posedge clk25) begin
	  cmd_sprite_en <= (editando == 2'b10) && ~KEY[2];
	  cmd_poly_en <= (editando == 2'b11) && ~KEY[2];
	end

	assign cmd_sprite_data = {
	  sel_sprite,
	  flip_v,
	  flip_h,
	  sel_show_s,
	  pos_y_s[sel_sprite], 
	  pos_x_s[sel_sprite]  
	};

	assign cmd_poly_data = {
	  sel_poly,
	  sel_tipo_p,
	  sel_show_p,
	  sel_cor_p,
	  pos_y_p[sel_poly],
	  pos_x_p[sel_poly]
	};

endmodule

module Contador32(
	input clk,
	input rst,
	input aumentando, diminuindo,
	output reg [4:0] cont
);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			cont <= 5'd0;
		end 
		else if(aumentando && cont< 5'd31) begin
			cont <= cont + 5'd1;
		end
		else if(diminuindo && cont > 5'd0) begin
			cont <= cont - 5'd1;
		end
		else begin
			cont <= cont;
		end
	end

endmodule

module Contador8(
	input clk,
	input rst,
	input aumentando, diminuindo,
	output reg [2:0] cont
);

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			cont <= 3'd0;
		end 
		else if(aumentando && cont < 3'd7) begin
			cont <= cont + 3'd1;
		end
		else if(diminuindo && cont > 3'd0) begin
			cont <= cont - 3'd1;
		end
		else begin
			cont <= cont;
		end
	end

endmodule