`timescale 1ns / 1ps
//Praktikum TGDI WS 09/10
//In dieser Datei soll die FPU implementiert werden.
//Diese Datei bitte als Lsung einschicken.

module fpu(
  input        clk,              //Takt
  input        reset,            //Reset-Signal
  input[31:0]  instruction,      //aktueller Befehl
  input[31:0]  mem_readdata,     //Lesedaten vom Speicher zum Registersatz (fuer lwc1)
  output[31:0] mem_writedata,    //Schreibdaten vom Registersatz (Port 1) an Speicher (fuer swc1)
  
  input regdst,                  //Gibt an, welcher Teil des Befehls als Adresse fuer den Write Port
                                 //des FPU-Registersatzes verwendet wird
                                 //0: Zielregister aus dem FP-Befehl
                                 //1: instruction[20:16] (lwc1, swc1)
  input fpuregwritemux,          //Gibt an, woher die Daten am Write Port des Registersatzes stammen
                                 //0: Daten ist Ergebnis aus FPU
                                 //1: Daten aus Speicher
  
  input fpu_regwrite             //Write_enable des FPU-Registersatzes
);

	wire [31:0] mem_data1, mem_data2;
	wire [31:0] res_add, res_sub, res_mult;
	wire [31:0] dummy_1;
	
	wire notwrite;
	
	assign notwrite = 0;

	//lese daten aus fpu-memory
	float_memory RAM(	clk,
							notwrite,			
							instruction[15:11], instruction[20:16], instruction[10:6], //2xquellregister,1xZiel
							mem_readdata, //does not write!
							mem_data1, mem_data2);

	//calculate values
	float_add adder(mem_data1,mem_data2,res_add);
	float_sub subber(mem_data1,mem_data2,res_sub);
	float_mult multer(mem_data1,mem_data2,res_mult);
	
	reg [31:0] result;
	wire [31:0] swc1_res;

	always@(*)
	begin
		//float-berechnung
		case(instruction[5:0]) 		//Funktion, wleche aufgerufen wird 
			6'b000000 :	 result = res_add;	//addition
			6'b000001 :	 result = res_sub;	//subtraktion
			6'b000010 :	 result = res_mult;	//multiplikation
			default: result = res_add;			//default = addieren
		endcase
		
		if(regdst & fpuregwritemux & fpu_regwrite) //lwc1-befehl
			result = mem_readdata;	//ergebnis = eingegebene daten
	end

	//schreibe memory -> bei swc1-befehl oder wenn float-berechnung durchgeführt wurde!
	float_memory write_mem(	clk,
									fpu_regwrite,
									instruction[15:11], instruction[20:16], instruction[10:6],
									result,
									swc1_res,dummy_1); //lese daten aus speicher
				
	//Output: entweder result bei float/lwc1 oder swc1_res bei swc1
	assign mem_writedata = (regdst & !fpuregwritemux & !fpu_regwrite)/*swc1*/ ? swc1_res : result /*float / lwc1*/;

endmodule

//Registersatz
module float_memory(
		input clk,													//Clock
		input write_enable,										//schreibe ja/nein
		input [4:0] read_addr1, read_addr2, write_addr,	//lese und schreibaddressen
		input [31:0] write_data,								//daten zum schreiben
		output[31:0] read_data1,read_data2					//ausgelesene daten
		);
			
	//Speicher
	reg [31:0] RAM[31:0];
		
	//schreiben
	always@(posedge clk)
		if(write_enable & write_addr != 0)
			RAM[write_addr] <= write_data;
			
	//lesen
	assign read_data1 = RAM[read_addr1];
	assign read_data2 = RAM[read_addr2];
	
endmodule

//Float-Multiplikator
module float_mult(
		input [31:0] read_data1,read_data2,	//Arbeitsdaten
		output [31:0] result); 					//achtung, rundet die Zahl
		
		wire vz1;
		wire [10:0] exp1;
		reg [20:0] mant1;
		
		wire vz2;
		wire [10:0] exp2;
		reg [20:0] mant2;
		
		reg [10:0] shiftamount;
		
		reg [10:0] new_exp;	
		reg new_vz;
		reg [41:0] new_mant;
		
		//assigns
			//teile read_data1 auf in vz1, exp1
			assign vz1 = read_data1[31];
			assign exp1 = read_data1[30:20];
			//teile read_data2 auf in vz2, exp2
			assign vz2 = read_data2[31];
			assign exp2 = read_data2[30:20];
		
		//always
		always@(*)
			begin
				//mantisse um 1 erweitern
				mant1[20] = 1;
				mant1[19:0] = read_data1[19:0];
				//mantisse um 1 erweitern
				mant2[20] = 1;
				mant2[19:0] = read_data2[19:0];
				
				//exponent
				new_exp = exp1 + (exp2 - 1023); //nur 1x bias! (11 bit deshalb bias=1023)
				
				//vorzeichen
				if(vz1 == vz2)
					new_vz = 0; //+
				else
					new_vz = 1; //-
				
				//mantisse
				new_mant = mant1 * mant2; //auf 42 bit gemapt
				
				//shift back -> jetzt steht die erste 1 in der 21 stelle = new_mant[20]
				if(new_mant[41] == 1) //höchstes bit ist gesetzt?
				begin
					new_mant = new_mant >> 20; //schifte um 20
					new_exp = new_exp + 20; //addiere 20 auf den exp
				end else
				begin
					new_mant = new_mant >> 19;	//oberstes bit ist nicht gesetzt = zweithöchstes bit ist gesetzt, shifte um 19
					new_exp = new_exp + 19; //addiere 19 auf exp
				end
			end
			
			assign result[31] = new_vz; //neues vorzeichen
			assign result[30:20] = new_exp; //neuer exponent
			assign result[19:0] = new_mant[19:0]; //neue mantisse
		
endmodule

//Addierer
module float_add(
		input  [31:0] read_data1, read_data2,	//Arbeitsdaten
		output [31:0] result);						//Ergebniss
			
		wire vz1;
		wire [10:0] exp1;
		reg [20:0] mant1;
		
		wire vz2;
		wire [10:0] exp2;
		reg [20:0] mant2;
		
		reg [10:0] shiftamount;
		
		reg [10:0] new_exp;	
		reg new_vz;
		reg [21:0] new_mant;
		
		//assigns
			//teile read_data1 auf in vz1, exp1
			assign vz1 = read_data1[31];
			assign exp1 = read_data1[30:20];
			//teile read_data2 auf in vz2, exp2
			assign vz2 = read_data2[31];
			assign exp2 = read_data2[30:20];
		
		//always
		always@(*)
			begin
				//mantisse um 1 erweitern
				mant1[20] = 1;
				mant1[19:0] = read_data1[19:0];
				//mantisse um 1 erweitern
				mant2[20] = 1;
				mant2[19:0] = read_data2[19:0];
			
					//exponentenvergleich, new_exp = größerer exp, shifte kleinere Zahl
					if(exp1 >= exp2)
						begin
							shiftamount = exp1 - exp2;
							mant2 = mant2 >> shiftamount[10:0];
							new_exp = exp1;
						end else
						begin
							shiftamount[10:0] = exp2 - exp1;			
							mant1 = mant1 >> shiftamount[10:0];
							new_exp = exp2;
						end
						
				//vorzeichen
				if(mant1 >= mant2)
					begin
						new_vz = vz1;
					end else
						begin
							new_vz = vz2;
						end
			
				if(vz1 == vz2) //vorzeichen sind gleich
					begin
						new_mant[21:0] = mant1 + mant2; //addiere
					end else
						begin
						if(vz1 > vz2) //read_data1 ist negativ
							begin
								new_mant[21:0] = mant2 - mant1;
							end else //read_data2 ist negativ
								begin
								new_mant[21:0] = mant1 - mant2;
								end
						end
			
				if(new_mant[21] == 1) //übertrag -> zurückshiften
				begin
					new_mant = new_mant >> 1;
					new_exp = new_exp + 1;
				end
			end
			
			//zusammen bauen
			assign result[31] = new_vz;
			assign result[30:20] = new_exp;
			assign result[19:0] = new_mant[19:0];
endmodule

//subtrahierer
module float_sub(
		input[31:0] read_data1, read_data2,		//Arbeitsdaten
		output [31:0] result);						//Ergebniss
		
		wire [31:0] data2;
		
		assign data2[30:0] = read_data2[30:0];
		assign data2[31] = (read_data2[31] == 1) ? 0 : 1;	//vertausche vorzeichen von read_data2
		
		//Addiere read_data1 und read_data2(mit geändertem vorzeichen)
		float_add add(read_data1, data2,result);
endmodule
