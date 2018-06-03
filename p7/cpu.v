`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);

    reg halt = 0;

    counter ctr(halt,clk);

    // PC
    reg [15:0]pc = 16'h0000;

    // read from memory
    wire [15:0]instr;
	wire [15:0]lddata;	

	wire wen0 = io & st;
    mem mem(clk,
		pc,instr,
		wen0,vaio,vtio,
		vaio,lddata);

    // register file
    reg [15:0]rf[0:15];
	initial rf[0] = 16'd0;


	wire [3:0] opcode = instr[15:12];

	wire isSub = (opcode == 0);
	wire [3:0] ra = instr[11:8];
	wire [3:0] rb = instr[7:4];
	wire [3:0] rt = instr[3:0];
	wire [15:0] va = rf[ra];
	wire [15:0] vb = rf[rb];
	wire [15:0] subVal = va - vb;

	wire ismovl = (opcode == 4'b1000);
	wire [7:0]i = instr[11:4];
	wire [15:0]extmovl = { {8{i[7]}}, {i} };
	wire [3:0]rtmovl = instr[3:0];

	wire ismovh = (opcode == 4'b1001);
	wire [7:0]imovh = instr[11:4];
	wire [3:0]rtmovh = instr[3:0];
	wire [15:0]extmovh = { {imovh}, {rf[rtmovh][7:0]} };

	wire isjz = (opcode == 4'b1110);
	wire [3:0]rajz = instr[11:8];
	wire [3:0]jztype = instr[7:4];
	wire [3:0]rtjz = instr[3:0];
	wire [15:0]vajz = rf[rajz];
	wire [15:0]vtjz = rf[rtjz];
		wire jz = (jztype == 4'b0000);
		wire jnz = (jztype == 4'b0001);
		wire js = (jztype == 4'b0010);
		wire jns = (jztype == 4'b0011);
	wire jumping = isjz & (jz | jnz | js | jns);
	
	wire io = (opcode == 4'b1111);
	wire [3:0]raio = instr[11:8];
	wire [15:0] vaio = rf[raio];
	wire [3:0]iotype = instr[7:4];
	wire ld = (iotype == 4'b0000);
	wire st = (iotype == 4'b0001);
	wire ioing = io & (ld | st);
	wire [3:0]rtio = instr[3:0];
	wire [15:0]vtio = rf[rtio];

	wire defined = (isSub | ismovl | ismovh | jumping | ioing);
    
	always @(posedge clk) begin
        if (defined == 0) begin
            halt <= 1;
        end
		if( ^defined === 1'bx) begin
			halt <= 1;
		end

		if(ismovl) begin
//			$write("movl %d <- %d", rtmovl, extmovl);
			if(rtmovl != 0) begin
				rf[rtmovl] <= extmovl;
			end
			if(rtmovl == 0) begin
				$write("%c", extmovl[7:0]);
			end
		end
		if(isSub) begin
//			$write("isSub %d <- %d",rt, subVal );
			if(rt != 0) begin
				rf[rt] <= subVal;
			end
			if(rt == 0) begin
				$write("%c", subVal[7:0]);
			end
		end
		if(ismovh) begin
//			$write("ismovh %d <- %d", rtmovh, extmovh);
			if(rtmovh != 0) begin
				rf[rtmovh] <= extmovh;
			end
			if(rtmovh == 0) begin
				$write("%c", extmovh[7:0]);
			end
		end
		
		if(isjz) begin
//			$write("isjz (%d) -> %d", vajz, vtjz);
			if(jz) begin
//				$write("jz");
				pc <= (vajz == 0) ? vtjz : (pc + 2);
			end
			if(jnz) begin
//				$write("jnz");
				pc <= (vajz != 0) ? vtjz : (pc + 2);
			end
			if(js) begin
//				$write("js");
				pc <= (vajz[15] == 1) ? vtjz : (pc + 2);
			end
			if(jns) begin
//				$write("jns");
				pc <= (vajz[15] == 0) ? vtjz : (pc + 2);
			end
		end
		if(io) begin
//			$write("io");
			if(ld) begin
//				$write("ld %d <- %d", rtio, lddata);
				if(rtio != 0) begin
					rf[rtio] <= lddata;	
				end
				if(rtio == 0) begin
					$write("%c", lddata[7:0]);
				end
			end
			if(wen0) begin
//				$write("st %d <- %d", vaio, vtio);
			end
		end
//		$display("%d\n", pc);
		if(isjz == 0) begin
        	pc <= pc + 2;
		end
    end


endmodule
