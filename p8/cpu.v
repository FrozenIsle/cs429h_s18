`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);
	
	//some constants
    reg halt = 0;
	reg [16:0]max = 17'b10000000000000000;
    counter ctr(halt,clk);
	reg pactions = 0;
	reg pstate = 0;

    // PC
    reg [15:0]pc = 16'h0000;

    // read from memory
    wire [15:0]instr;
	wire [15:0]lddata;	

    // register files
    reg [15:0]rf[0:15];
	initial rf[0] = 16'd0;
	initial rf[1] = 16'd0;
	initial rf[2] = 16'd0;
	initial rf[3] = 16'd0;
	initial rf[4] = 16'd0;
	initial rf[5] = 16'd0;
	initial rf[6] = 16'd0;
	initial rf[7] = 16'd0;
	initial rf[8] = 16'd0;
	initial rf[9] = 16'd0;
	initial rf[10] = 16'd0;
	initial rf[11] = 16'd0;
	initial rf[12] = 16'd0;
	initial rf[13] = 16'd0;
	initial rf[14] = 16'd0;
	initial rf[15] = 16'd0;

	//state
	// 0 = read, 1 = act, 2 = write2, 3 = read2
	reg[1:0] state = 2'b00;
	reg rCount = 0;

	// memory interaction
	wire wen;
	wire [15:0] rAdd;
	wire [7:0] rData;
	wire [15:0] wAdd;
	wire [7:0] wData;
	
	mem mem(clk,
		rAdd,rData,
		wen,wAdd,wData);
	
	// instr
	reg [7:0]prevInstr = 0;
	assign instr = {prevInstr, rData};

	wire [3:0] opcode = instr[15:12];

	//sub
	wire isSub = (opcode == 0);
	wire [3:0] ra = instr[11:8];
	wire [3:0] rb = instr[7:4];
	wire [3:0] rt = instr[3:0];
	wire [15:0] va = rf[ra];
	wire [15:0] vb = rf[rb];
	wire [15:0] subVal = va - vb;

	//movl
	wire ismovl = (opcode == 4'b1000);
	wire [7:0]i = instr[11:4];
	wire [15:0]extmovl = { {8{i[7]}}, {i} };
	wire [3:0]rtmovl = instr[3:0];

	//movh
	wire ismovh = (opcode == 4'b1001);
	wire [7:0]imovh = instr[11:4];
	wire [3:0]rtmovh = instr[3:0];
	wire [15:0]extmovh = { {imovh}, {rf[rtmovh][7:0]} };

	//jz
	wire isjz = (opcode == 4'b1110);
	wire [3:0]rajz = instr[11:8];
	wire [3:0]jztype = instr[7:4];
	wire [3:0]rtjz = instr[3:0];
	wire [15:0]vajz = rf[rajz];
	wire [15:0]vtjz = rf[rtjz];
	wire jz = (jztype == 4'b0000) & isjz & (vajz == 0);
	wire jnz = (jztype == 4'b0001) & isjz & (vajz != 0);
	wire js = (jztype == 4'b0010) & isjz & (vajz[15] == 1);
	wire jns = (jztype == 4'b0011) & isjz & (vajz[15] == 0);
	wire jumping = (jz | jnz | js | jns);
	wire triedJump = isjz & (jztype == 4'b0000 | jztype == 4'b0001 | jztype == 4'b0010 | jztype == 4'b0011);
	
	//io
	wire io = (opcode == 4'b1111);
	wire [3:0]raio = instr[11:8];
	wire [15:0] vaio = rf[raio];
	wire [3:0]iotype = instr[7:4];
	wire ld = (iotype == 4'b0000) & io;
	wire st = (iotype == 4'b0001) & io;
	wire [15:0]ioing = io & (ld | st);
	wire [3:0]rtio = instr[3:0];
	wire [15:0]vtio = rf[rtio];

	//register
	wire [3:0]regAdd = 
		{4{state == 1}} & (
			{4{ismovl}} & rtmovl | 
			{4{ismovh}} & rtmovh | 
			{4{isSub}} & rt) | 
		{4{rCount == 1}} & prevRegAdd;
	wire [15:0]regData = 
		{16{state == 1}} & (
			{16{ismovl}} & extmovl | 
			{16{ismovh}} & extmovh | 
			{16{isSub}} & subVal) | 
		{16{rCount == 1}} & lddata;
	wire regWen = (ismovl & state == 1 | ismovh & state == 1 | isSub & state == 1 | rCount == 1);
	
	//defined
	wire defined = (isSub | ismovl | ismovh | triedJump | ioing | state != 1);

	//pc, used only in state == 1
	wire [15:0]nextpc = ({16{jumping}} & vtjz) | ((~{16{jumping}}) & ((pc + 2)%max));

	//state
	wire [1:0]nextState = 
		{2{state == 0}} & 2'b01 | 
		{2{state == 1}} & (
			{2{isSub | ismovl | ismovh | triedJump}} & 2'b00 |
			{2{st}} & 2'b10 |
			{2{ld}} & 2'b11) |
		{2{state == 2}} & 2'b01 |
		{2{state == 3}} & (
			{2{rCount == 0}} & 2'b11 |
			{2{rCount == 1}} & 2'b00);
	
	//read address
	assign rAdd = 
		{16{state == 0}} & pc |
		{16{state == 1}} & ((pc + 1)%max) | 
		{16{state == 2}} & pc |
		{16{state == 3}} & (
			{16{rCount == 0}} & prevReadAdd |
			{16{rCount == 1}} & ((prevReadAdd+1)%max) );

	//write
	reg [7:0]prevWrite = 0;
	reg [15:0]prevWriteAdd = 0;
	assign wen = (state == 1 && st) | (state == 2);
	assign wAdd = {16{state == 1}} & vaio | {16{state == 2}} & ((prevWriteAdd+1)%max);
	assign wData = {8{state == 1}} & vtio[15:8] | {8{state == 2}} & prevWrite;
	
	//read
	reg [15:0]prevReadAdd = 0;
	reg [15:0]prevRegAdd = 0;
	reg [7:0]prevRead = 0;
	assign lddata = {prevRead, rData};

	
	always @(posedge clk) begin
        if (defined == 0) begin
            halt <= 1;
			$write("\n");
        end
		if( ^defined === 1'bx) begin
			halt <= 1;
			$write("\n");
		end

		if(regWen) begin
			if(regAdd == 0) begin
				if(pactions ==0) begin
					$write("%c", regData[7:0]);
				end
				if(pactions) begin
					$display("print %d\n", regData[7:0]);
				end
			end
			if(regAdd != 0) begin
				rf[regAdd] <= regData;
				if(pactions) begin
					$display("reg %d <= %d\n", regAdd, regData);
				end
			end
		end
	
		if(state == 0 || state == 2) begin
			prevInstr <= rData;
		end

		if(rCount == 1) begin
			rCount <= 0;
		end
		if(state == 3 && rCount == 0) begin
			prevRead <= rData;
			rCount <= 1;
		end

		if(state == 1) begin
			prevWrite <= vtio[7:0];
			prevWriteAdd <= vaio;
			prevRegAdd <= rtio;
			prevReadAdd <= vaio;
		end

		state <= nextState;
		if(state == 1) begin
			pc <= nextpc;
		end

		if(wen & pactions) begin
			$display("mem %d <= %d\n", wAdd, wData);
		end
		
		if(pstate) begin
			$display("pc = %d, state = %d, Rwen = %d, regAdd = %d, rCount = %d", pc, state, regWen, regAdd, rCount);
		end
//		$display("%b", {16{state == 1}} & ((pc + 1)%max));
    end


endmodule
