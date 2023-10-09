module TrafficLightController(SW, KEY, HEX7, HEX6, HEX3, HEX2, HEX1, HEX0);
	input [17:0] SW;
   input [0:0] KEY;
   output [6:0] HEX7, HEX6, HEX3, HEX2, HEX1, HEX0;
	
   controller CTRL(.W(SW[0]), .EL(SW[1]), .NL(SW[2]), .E(SW[3]), .Reset(SW[17]), .Clock(KEY[0]), .WTL(HEX0[6:0]), .ELTL(HEX1[6:0]), .NTL(HEX2[6:0]), .ETL(HEX3[6:0]), .hexr(HEX6), .hexl(HEX7));
	
endmodule

module numtohex(number, hex6, hex7);
	input [2:0] number;
	output [6:0] hex6, hex7;
	
	reg [6:0] lookup_r[0:7];
	reg [6:0] lookup_l[0:7];
	
	initial begin
		lookup_r[0] = 7'b1000000;
		lookup_r[1] = 7'b1111001;
		lookup_r[2] = 7'b0100100;
		lookup_r[3] = 7'b0110000;
		lookup_r[4] = 7'b0011001;
		lookup_r[5] = 7'b0010010;
		lookup_r[6] = 7'b0000010;
		lookup_r[7] = 7'b1111000;
		
		lookup_l[0] = 7'b1111111;
		lookup_l[1] = 7'b1111111;
		lookup_l[2] = 7'b1111111;
		lookup_l[3] = 7'b1111111;
		lookup_l[4] = 7'b1111111;
		lookup_l[5] = 7'b1111111;
		lookup_l[6] = 7'b1111111;
		lookup_l[7] = 7'b1111111;
	end
	
	assign hex6 = lookup_r[number];
	assign hex7 = lookup_l[number];
	
endmodule

module controller(W, EL, NL, E, Reset, Clock, WTL, ELTL, NTL, ETL, hexl, hexr);
   reg [2:0] Q;
   reg [2:0] D;
	input W, EL, NL, E, Reset, Clock;
   output [6:0] WTL, ELTL, NTL, ETL;
   reg [2:0] Timer;
	output [6:0] hexl, hexr;
	
	reg [6:0] WTL, ELTL, NTL, ETL;
	numtohex nh(Timer, hexr, hexl);
	
	parameter Green = 7'b0010000; // Lower case g
	parameter Yellow = 7'b0010001; // Lower case y
	parameter Red = 7'b0101111; // Lower case r
   parameter ELGreen = 3'b000;
   parameter ELYellow = 3'b001;
   parameter EWGreen = 3'b010;
   parameter EGreenWYellow = 3'b011;
   parameter EWYellow = 3'b100;
	parameter ENLGreen = 3'b101;
	parameter EGreenNLYellow = 3'b110;
	parameter ENLYellow = 3'b111;


// state transition
	always @*
	begin
		case(Q)
			ELGreen: 			if (Timer >= 3 & ((NL == 1 | E == 1 | W == 1) | (EL == 0 & NL == 0 & E == 0 & W == 0)))  
										D <= ELYellow;
									else
										D <= ELGreen;
			ELYellow: 			if (Timer == 1 & ((E == 1 & NL == 0) | (W == 1 & NL == 0)))
										D <= EWGreen;
									else if (Timer == 1 & ((E == 1 & W == 0) | NL == 1) | (EL == 0 & NL == 0 & E == 0 & W == 0))
										D <= ENLGreen;
									else
										D <= ELYellow;
			EWGreen: 			if (Timer >= 3 & (NL == 1 & EL == 0))
										D <= EGreenWYellow;
									else if (Timer >= 3 & (EL == 1 | EL == 0 & NL == 0 & E == 0 & W == 0))
										D <= EWYellow;
									else
										D <= EWGreen;
			EGreenWYellow: 	if (Timer == 1)
										D <= ENLGreen;
									else
										D <= EGreenWYellow;
			EWYellow: 			if (Timer == 1)
										D <= ELGreen;
									else
										D <= EWYellow;
			ENLGreen: 			if (Timer >= 3 & (W == 1 | (EL == 0 & NL == 0 & E == 0 & W == 0)))
										D <= EGreenNLYellow;
									else if (Timer >= 3 & (W == 0 & EL == 1))
										D <= ENLYellow;
									else
										D <= ENLGreen;
			EGreenNLYellow: 	if (Timer == 1)
										D <= EWGreen;
									else
										D <= EGreenNLYellow;
			ENLYellow:			if (Timer == 1)
										D <= ELGreen;
									else
										D <= ENLYellow;
		endcase
	end

// set the flipflops
	always @(posedge Clock)
	begin
		if(Reset) begin
			Q <= 3'b000;
			Timer <= 3'b000;
			end
		else if (Q == D) begin
			Timer <= Timer + 1;
			end
		else begin
			Timer <= 3'b000;
			Q <= D;
			end
	end
			
// output equations
    // setting the hexes for output
		 	always @*
			begin
				case(Q)
					ELGreen: begin
								ELTL = Green;
								NTL = Red;
								ETL = Red;
								WTL = Red;
							end
					ELYellow: begin
								ELTL = Yellow;
								NTL = Red;
								ETL = Red;
								WTL = Red;
							end
					EWGreen: begin
								ELTL = Red;
								NTL = Red;
								ETL = Green;
								WTL = Green;
							end
					EGreenWYellow: begin
								ELTL = Red;
								NTL = Red;
								ETL = Green;
								WTL = Yellow;
							end
					EWYellow: begin
								ELTL = Red;
								NTL = Red;
								ETL = Yellow;
								WTL = Yellow;
							end
					ENLGreen: begin
								ELTL = Red;
								NTL = Green;
								ETL = Green;
								WTL = Red;
							end
					EGreenNLYellow: begin
								ELTL = Red;
								NTL = Yellow;
								ETL = Green;
								WTL = Red;
							end
					ENLYellow: begin
								ELTL = Red;
								NTL = Yellow;
								ETL = Yellow;
								WTL = Red;
							end
				endcase
			end
endmodule

			