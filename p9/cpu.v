`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

	/////////////
    // Basics1 //
	/////////////
    wire clk;
    clock c0(clk);

    reg halt = 0;

	reg [16:0]max = 17'b10000000000000000;
	reg [16:1]max2 = 16'b1000000000000000;

    counter ctr(halt,clk);

	wire [15:1] raddr0_;
	wire [15:0] rdata0_;
	wire [15:1] raddr1_;
	wire [15:0] rdata1_;
	wire wen;
	wire [15:1] waddr;
	wire [15:0] wdata;

	mem mem(clk,
    	raddr0_, rdata0_,
    	raddr1_, rdata1_,
    	wen, waddr, wdata);

	wire [3:0]regA;
	wire [15:0]regAData;
	wire [3:0]regB;
	wire[15:0]regBData;
	wire regWEn;
	wire [3:0]regW;
	wire [15:0]regWData;
	regs regs(clk,
		regA, regAData,
		regB, regBData,
		regWEn, regW, regWData);

	////////////
    // Fetch1 //
	////////////
	wire f1_enable = 1;
	wire f1_freeze = f1_enable & (
		l1_addr0En & f1_addr0En | l1_addr1En & f1_addr1En);
	wire f1_wipe = f2_wipe;
	reg [15:0]f1_PC = 0;
	wire [15:1] f1_raddr0 = f1_PC[15:1];
	wire [15:1] f1_raddr1 = (f1_raddr0 + 1)%max2;
	wire f1_odd = f1_PC[0];

	wire f1_active = f1_enable & ~f1_freeze & ~f1_wipe;

	// assign to mem
	wire f1_addr0En = f1_enable;
	wire [15:1]f1_addr0 = f1_raddr0;
	wire f1_addr1En = f1_odd;
	wire [15:1]f1_addr1 = f1_raddr1;

    always @(posedge clk) begin
		if(~f1_freeze & ~f1_wipe)begin
			f1_PC <= ((f1_PC + 2)%max);
		end
		if(f1_freeze & ~f1_wipe)begin
		
		end
		if(f1_wipe)begin
			f1_PC <= wipePC;
		end
    end	

	////////////
	// Fetch2 //
	////////////
	reg f2_enable = 0;
	wire f2_wipe = f2_enable & d_freeze | d_wipe;
	reg [15:0]f2_PC;
	reg [15:1]f2_raddr0;
	reg [15:1]f2_raddr1;
	reg f2_odd;
	wire f2_active = f2_enable & ~f2_wipe;
    always @(posedge clk) begin
		if(~f2_wipe)begin
	        f2_enable <= f1_active;
			f2_PC <= f1_PC;
			f2_raddr0 <= f1_raddr0;
			f2_raddr1 <= f1_raddr1;
			f2_odd <= f1_odd;
		end

		if(f2_wipe)begin
	        f2_enable <= 0;
			f2_PC <= 0;
			f2_raddr0 <= 0;
			f2_raddr1 <= 0;
			f2_odd <= 0;
		end
    end	

	/////////////
	// Decoder //
	/////////////
	reg d_enable = 0;
	reg d_odd;
	wire d_freeze = d_enable & ~valid;	//halter
	reg d_postfreeze;
	reg [15:0]d_saverdata0_;
	reg [15:0]d_saverdata1_;
	wire [15:0]d_userdata0_ = 
		{16{~d_postfreeze}} & rdata0_ |
		{16{d_postfreeze}} & d_saverdata0_;
	wire [15:0]d_userdata1_ = 
		{16{~d_postfreeze}} & rdata1_ |
		{16{d_postfreeze}} & d_saverdata1_;
	wire d_wipe = e_freeze | e_wipe | l1_wipe | e_willJmp | d_enable & (
		s2_enable & (
			(s2_memaddr2 == d_raddr0) |
			(s2_memaddr2 == d_raddr1) & d_odd
		) |
		s1_enable & (
			(s1_memaddr1 == d_raddr0) |
			(s1_memaddr1 == d_raddr1) & d_odd
		) |
		s1_enable & s1_memodd & (
			(s1_memaddr2 == d_raddr0) |
			(s1_memaddr2 == d_raddr1) & d_odd
		)
	);
	reg [15:0]d_PC;
	reg [15:1]d_raddr0;
	reg [15:1]d_raddr1;

	
	wire [15:0]instr = 
		{16{d_odd == 0}} & d_userdata0_ |
		{16{d_odd == 1}} & {d_userdata0_[7:0], d_userdata1_[15:8]};

	wire [3:0] opcode = instr[15:12];

	//sub
	wire isSub = (opcode == 0);
	wire [3:0]subA = instr[11:8];
	wire [3:0]subB = instr[7:4];
	wire [3:0]subT = instr[3:0];

	//movl
	wire ismovl = (opcode == 4'b1000);
	wire [7:0]i = instr[11:4];
	wire [15:0]extmovl = { {8{i[7]}}, {i} };
	wire [3:0]movT = instr[3:0];

	//movh
	wire ismovh = (opcode == 4'b1001);
	wire [7:0]imovh = instr[11:4];
	//extmovh later

	//jmp
	wire [3:0]jmpA = instr[11:8];
	wire [3:0]jmpType = instr[7:4];
	wire [3:0]jmpT = instr[3:0];
	wire jz = (jmpType == 4'b0000);
	wire jnz = (jmpType == 4'b0001);
	wire js = (jmpType == 4'b0010);
	wire jns = (jmpType == 4'b0011);
	wire isjmp = (opcode == 4'b1110) &
		(jz | jnz | js | jns);
	
	//io
	wire [3:0]ioA = instr[11:8];
	wire [3:0]iotype = instr[7:4];
	wire ld = (iotype == 4'b0000);
	wire st = (iotype == 4'b0001);
	wire [3:0]ioT = instr[3:0];
	wire isio = (opcode == 4'b1111) &
		(ld | st);

	//halt
	wire valid = (isSub | ismovh | ismovl | isjmp | isio);
	wire execute = (isSub | ismovh | ismovl | isjmp);
	wire load = (isio);

	///////////////
	// Registers //
	///////////////
	wire r_regAEn = (isSub | isjmp | isio);
	wire [3:0]r_regA = subA;
	wire r_regBEn = (isSub | ismovh | isjmp | (isio & st));
	wire [3:0]r_regB = 
		{4{isSub}} & subB |
		{4{ismovh}} & movT |
		{4{isjmp}} & jmpT |
		{4{isio & st}} & ioT;
	wire r_regWEn = (isSub | ismovh | ismovl | (isio&ld));
	wire [3:0]r_regW = 
		{4{isSub}} & subT |
		{4{ismovh | ismovl}} & movT |
		{4{isio&ld}} & ioT;

	wire d_active = d_enable & ~d_freeze & ~d_wipe;
	// registers assign

    always @(posedge clk) begin
		if(~d_freeze & ~d_wipe) begin
	        d_enable <= f2_active;
			d_PC <= f2_PC;
			d_raddr0 <= f2_raddr0;
			d_raddr1 <= f2_raddr1;
			d_odd <= f2_odd;

			d_postfreeze <= 0;
			d_saverdata0_ <= 0;
			d_saverdata1_ <= 0;
		end
		if(d_freeze & ~d_wipe) begin
			if(~e_active & ~l1_active & ~l2_active & ~l3_active &
				~s1_active & ~s2_active)begin
				halt <= 1;			
			end
			d_postfreeze <= 1;
			d_saverdata0_ <= d_userdata0_;
			d_saverdata1_ <= d_userdata1_;
		end
		if(d_wipe) begin
	        d_enable <= 0;
			d_PC <= 0;
			d_raddr0 <= 0;
			d_raddr1 <= 0;
			d_odd <= 0;

			d_postfreeze <= 0;
			d_saverdata0_ <= 0;
			d_saverdata1_ <= 0;
		end
    end	

	/////////////////////////
	// Execute Sub/Jmp/Mov //
	/////////////////////////
	reg e_enable = 0;
	reg e_odd;
	wire e_freeze = e_enable & (
		l3_enable |
		l2_enable & (l2_regW == e_regW) & e_regWEn
	);
	reg e_postfreeze = 0;
	reg [15:0]e_saveregAData;
	reg [15:0]e_saveregBData;
	wire [15:0]e_useregAData = 
		{16{~e_postfreeze}} & (
			{16{e_regA != 0}} & regAData |
			{16{e_regA == 0}} & {16{1'b0}}
		) |
		{16{e_postfreeze}} & e_saveregAData;
	wire [15:0]e_useregBData = 
		{16{~e_postfreeze}} & (
			{16{e_regB != 0}} & regBData |
			{16{e_regB == 0}} & {16{1'b0}}
		) |
		{16{e_postfreeze}} & e_saveregBData;
	wire e_wipe = l1_wipe | e_enable & (
			s2_enable & (
				(s2_memaddr2 == e_raddr0) |
				(s2_memaddr2 == e_raddr1) & e_odd
			) |
			s1_enable & (
				(s1_memaddr1 == e_raddr0) |
				(s1_memaddr1 == e_raddr1) & e_odd
			) |
			s1_enable & & s1_memodd & (
				(s1_memaddr2 == e_raddr0) |
				(s1_memaddr2 == e_raddr1) & e_odd
			) | 
			l3_enable & (
				(l3_regW == e_regA) & e_regAEn |
				(l3_regW == e_regB) & e_regBEn
			) |
			l2_enable & (
				(l2_regW == e_regA) & e_regAEn |
				(l2_regW == e_regB) & e_regBEn
			)
	);
	reg [15:0]e_PC;
	reg [15:1]e_raddr0;
	reg [15:1]e_raddr1;

	reg e_regAEn;
	reg e_regBEn;
	reg e_regWEn;
	reg [3:0]e_regA;
	reg [3:0]e_regB;
	reg [3:0]e_regW;

	reg e_isSub;

	reg e_isjmp;
	reg e_jz;
	reg e_jnz;
	reg e_js;
	reg e_jns;

	reg e_ismovl;
	reg [15:0]e_extmovl;

	reg e_ismovh;
	reg [7:0]e_imovh;

	//sub
	wire [15:0] subData = e_useregAData - e_useregBData;
	
	//movl
	wire [15:0] movlData = e_extmovl;

	//movh
	wire [15:0] origData = e_useregBData;
	wire [15:0] movhData = { {e_imovh, origData[7:0]} };
	
	wire e_active = e_enable & ~e_freeze & ~e_wipe;
	//reg write
	wire e_rregWEn = e_active & e_regWEn;
	wire [15:0]e_regWData = 
		{16{e_isSub}} & subData |
		{16{e_ismovl}} & movlData |
		{16{e_ismovh}} & movhData;

	//jmp make sure to jmp
	//1) wipe up pipe, and 
	//2) set f1_PC
	wire e_willJmp = e_active & e_isjmp & (
		e_jz & (e_useregAData == 0) |
		e_jnz & (e_useregAData != 0) |
		e_js & (e_useregAData[15] == 1) |
		e_jns & (e_useregAData[15] == 0)
		);
	wire [15:0]e_jmpPC = e_useregBData;

    always @(posedge clk) begin
		if(~e_freeze & ~e_wipe)begin
			e_enable <= d_active & execute;
			e_PC <= d_PC;
			e_raddr0 <= d_raddr0;
			e_raddr1 <= d_raddr1;
			e_odd <= d_odd;
			e_regAEn <= r_regAEn;
			e_regBEn <= r_regBEn;
			e_regWEn <= r_regWEn;
			e_regA <= r_regA;
			e_regB <= r_regB;
			e_regW <= r_regW;
	
			e_isSub <= isSub;
	
			e_isjmp <= isjmp;
			e_jz <= jz;
			e_jnz <= jnz;
			e_js <= js;
			e_jns <= jns;
	
			e_ismovl <= ismovl;
			e_extmovl <= extmovl;
	
			e_ismovh <= ismovh;
			e_imovh <= imovh;
			
			e_postfreeze <= 0;
			e_saveregAData <= 0;
			e_saveregBData <= 0;
		end
		if(e_freeze & ~e_wipe)begin
			e_postfreeze <= 1;
			e_saveregAData <= e_useregAData;
			e_saveregBData <= e_useregBData;
		end
		if(e_wipe)begin
			e_enable <= 0;
			e_PC <= 0;
			e_raddr0 <= 0;
			e_raddr1 <= 0;
			e_odd <= 0;
			e_regAEn <= 0;
			e_regBEn <= 0;
			e_regWEn <= 0;
			e_regA <= 0;
			e_regB <= 0;
			e_regW <= 0;
	
			e_isSub <= 0;
	
			e_isjmp <= 0;
			e_jz <= 0;
			e_jnz <= 0;
			e_js <= 0;
			e_jns <= 0;
	
			e_ismovl <= 0;
			e_extmovl <= 0;
	
			e_ismovh <= 0;
			e_imovh <= 0;

			e_postfreeze <= 0;
			e_saveregAData <= 0;
			e_saveregBData <= 0;
		end
    end	

	////////////
	// Load 1 //
	////////////
		reg l1_enable = 0;
		reg l1_odd;
		wire l1_wipe = l2_wipe | l1_enable & (
			s2_enable & (
				(s2_memaddr2 == l1_raddr0) |
				(s2_memaddr2 == l1_raddr1) & l1_odd
			) |
			s1_enable & (
				(s1_memaddr1 == l1_raddr0) |
				(s1_memaddr1 == l1_raddr1) & l1_odd
			) |
			s1_enable & s1_memodd & (
				(s1_memaddr2 == l1_raddr0) |
				(s1_memaddr2 == l1_raddr1) & l1_odd
			) | 
			l3_enable & (
				(l3_regW == l1_regA) |
				(l3_regW == l1_regB) & l1_regBEn
			)
		);
		reg [15:0]l1_PC;
		reg [15:1]l1_raddr0;
		reg [15:1]l1_raddr1;
	
		reg l1_regBEn;
		reg [3:0]l1_regA;
		reg [3:0]l1_regB;
		reg [3:0]l1_regW;
		reg [3:0]l1_regWEn;

		reg l1_ld;
		reg l1_st;

		wire l1_memodd = regAData[0];
		wire [15:1]l1_memaddr1 = regAData[15:1];
		wire [15:1]l1_memaddr2 = (l1_memaddr1 + 1)%max2;

		wire [15:0]l1_regData = regBData;

		wire l1_active = l1_enable & ~l1_wipe;
		//memory reads
		wire l1_addr1En = l1_active;
		wire [15:1]l1_addr1 = l1_memaddr1;
		wire l1_addr0En = l1_active & l1_memodd;
		wire [15:1]l1_addr0 = l1_memaddr2;

		//freeze f1 if conflicting
    always @(posedge clk) begin
		if(~l1_wipe)begin
			l1_enable <= d_active & load;
			l1_PC <= d_PC;
			l1_raddr0 <= d_raddr0;
			l1_raddr1 <= d_raddr1;
			l1_odd <= d_odd;
	
			l1_regBEn <= r_regBEn;
			l1_regA <= r_regA;
			l1_regB <= r_regB;
			l1_regWEn <= r_regWEn;
			l1_regW <= r_regW;

			l1_ld <= ld;
			l1_st <= st;
		end
		if(l1_wipe)begin
			l1_enable <= 0;
			l1_PC <= 0;
			l1_raddr0 <= 0;
			l1_raddr1 <= 0;
			l1_odd <= 0;
	
			l1_regBEn <= 0;
			l1_regA <= 0;
			l1_regB <= 0;
			l1_regWEn <= 0;
			l1_regW <= 0;

			l1_ld <= 0;
			l1_st <= 0;
		end
    end	

	////////////
	// Load 2 //
	////////////
		reg l2_enable = 0;
		reg l2_odd;
		wire l2_wipe = (l2_enable & s1_freeze) | s1_wipe | l3_wipe | l2_enable & (
			s2_enable& (
				(s2_memaddr2 == l2_raddr0) |
				(s2_memaddr2 == l2_raddr1) & l2_odd |
				(s2_memaddr2 == l2_memaddr1) |
				(s2_memaddr2 == l2_memaddr2) & l2_memodd
			) |
			s1_enable & (
				(s1_memaddr1 == l2_raddr0) |
				(s1_memaddr1 == l2_raddr1) & l2_odd |
				(s1_memaddr1 == l2_memaddr1) |
				(s1_memaddr1 == l2_memaddr2) & l2_memodd
			) |
			s1_enable & s1_memodd & (
				(s1_memaddr2 == l2_raddr0) |
				(s1_memaddr2 == l2_raddr1) & l2_odd |
				(s1_memaddr2 == l2_memaddr1) |
				(s1_memaddr2 == l2_memaddr2) & l2_memodd
			) |
			l3_enable & (
				(l3_regW == l2_regA) |
				(l3_regW == l2_regB) & l2_regBEn
			)
		);
		reg [15:0]l2_PC;
		reg [15:1]l2_raddr0;
		reg [15:1]l2_raddr1;
	
		reg l2_regBEn;
		reg [3:0]l2_regA;
		reg [3:0]l2_regB;
		reg l2_regWEn;
		reg [3:0]l2_regW;

		reg l2_ld;
		reg l2_st;

		reg l2_memodd;
		reg [15:1]l2_memaddr1;
		reg [15:1]l2_memaddr2;
		reg [15:0]l2_regData;

		wire l2_active = l2_enable & ~l2_wipe;
		// wipe l2_reg
		// freeze move into l2_regW
	
    always @(posedge clk) begin
		if(~l2_wipe)begin
			l2_enable <= l1_active;
			l2_PC <= l1_PC;
			l2_raddr0 <= l1_raddr0;
			l2_raddr1 <= l1_raddr1;
			l2_odd <= l1_odd;
		
			l2_regBEn <= l1_regBEn;
			l2_regA <= l1_regA;
			l2_regB <= l1_regB;
			l2_regWEn <= l1_regWEn;
			l2_regW <= l1_regW;		

			l2_ld <= l1_ld;	
			l2_st <= l1_st;

			l2_memodd <= l1_memodd;
			l2_memaddr1 <= l1_memaddr1;
			l2_memaddr2 <= l1_memaddr2;
			l2_regData <= l1_regData;
		end
		if(l2_wipe)begin
			l2_enable <= 0;
			l2_PC <= 0;
			l2_raddr0 <= 0;
			l2_raddr1 <= 0;
			l2_odd <= 0;
		
			l2_regBEn <= 0;
			l2_regA <= 0;
			l2_regB <= 0;
			l2_regWEn <= 0;
			l2_regW <= 0;		

			l2_ld <= 0;	
			l2_st <= 0;

			l2_memodd <= 0;
			l2_memaddr1 <= 0;
			l2_memaddr2 <= 0;
			l2_regData <= 0;
		end
    end	

	////////////
	// Load 3 //
	////////////
		reg l3_enable = 0;
		reg l3_memodd;
		reg l3_odd;
		wire l3_wipe = s1_wipe | l3_enable & (
			s2_enable & (
				(s2_memaddr2 == l3_raddr0) |
				(s2_memaddr2 == l3_raddr1) & l3_odd |
				(s2_memaddr2 == l3_memaddr1) |
				(s2_memaddr2 == l3_memaddr2) & l3_memodd
			) |
			s1_enable & (
				(s1_memaddr1 == l3_raddr0) |
				(s1_memaddr1 == l3_raddr1) & l3_odd |
				(s1_memaddr1 == l3_memaddr1) |
				(s1_memaddr1 == l3_memaddr2) & l3_memodd
			) |
			s1_enable & s1_memodd & (
				(s1_memaddr2 == l3_raddr0) |
				(s1_memaddr2 == l3_raddr1) & l3_odd |
				(s1_memaddr2 == l3_memaddr1) |
				(s1_memaddr2 == l3_memaddr2) & l3_memodd
			)
		);
		reg [15:0]l3_PC;
		reg [15:1]l3_raddr0;
		reg [15:1]l3_raddr1;
	
		reg [3:0]l3_regW;

		reg [15:1]l3_memaddr1;
		reg [15:1]l3_memaddr2;

		wire [15:0]l3_memData = 
			{16{l3_memodd == 0}} & rdata1_ |
			{16{l3_memodd == 1}} & {rdata1_[7:0], rdata0_[15:8]};

		wire l3_active = l3_enable & ~l3_wipe;
		//write to register
		wire l3_regWEn = l3_active;
		wire [15:0]l3_regWData = l3_memData;

		//wipe use of l3_regW
		// freeze moving into regW

    always @(posedge clk) begin
		if(~l3_wipe)begin
			l3_enable <= l2_active & l2_ld;
			l3_PC <= l2_PC;
			l3_raddr0 <= l2_raddr0;
			l3_raddr1 <= l2_raddr1;
			l3_odd <= l2_odd;
		
			l3_regW <= l2_regW;

			l3_memodd <= l2_memodd;
			l3_memaddr1 <= l2_memaddr1;
			l3_memaddr2 <= l2_memaddr2;
		end
		if(l3_wipe)begin
			l3_enable <= 0;
			l3_PC <= 0;
			l3_raddr0 <= 0;
			l3_raddr1 <= 0;
			l3_odd <= 0;
		
			l3_regW <= 0;

			l3_memodd <= 0;
			l3_memaddr1 <= 0;
			l3_memaddr2 <= 0;
		end
    end	

	////////////
	// Store1 //
	////////////
		reg s1_enable = 0;
		reg s1_odd;
		reg s1_memodd;	
		wire s1_freeze = s1_enable & s2_active;
		reg s1_postfreeze = 0;
		reg [15:0]s1_savedata0_;
		reg [15:0]s1_savedata1_;
		wire s1_wipe = s1_enable & (
			s2_enable & (
				(s2_memaddr2 == s1_raddr0) |
				(s2_memaddr2 == s1_raddr1) & s1_odd |
				(s2_memaddr2 == s1_memaddr1) |
				(s2_memaddr2 == s1_memaddr2) & s1_memodd
			)
		);
		reg [15:0]s1_PC;
		reg [15:1]s1_raddr0;
		reg [15:1]s1_raddr1;

		reg [15:1]s1_memaddr1;
		reg [15:1]s1_memaddr2;
		reg [15:0]s1_regData;

		wire [15:0]s1_usedata0_ = 
			{16{~s1_postfreeze}} & rdata0_ |
			{16{s1_postfreeze}} & s1_savedata0_;
		wire [15:0]s1_usedata1_ = 
			{16{~s1_postfreeze}} & rdata1_ |
			{16{s1_postfreeze}} & s1_savedata1_;

		wire [15:0]s1_stData1 = 
			{16{s1_memodd == 0}} &  s1_regData|
			{16{s1_memodd == 1}} & {s1_usedata1_[15:8], s1_regData[15:8]};
		wire [15:0]s1_stData2 = {s1_regData[7:0], s1_usedata0_[7:0]};

		//store 1
		wire s1_active = s1_enable & ~s1_freeze & ~s1_wipe;
		wire s1_wen = s1_active;
		wire [15:1]s1_waddr = s1_memaddr1;
		wire [15:0]s1_wdata = s1_stData1;

		//wipe s1_memaddr1 and s1_memaddr2
		//freeze nothing

    always @(posedge clk) begin
		if(~s1_freeze & ~s1_wipe) begin
			s1_enable <= l2_active & l2_st;
			s1_PC <= l2_PC;
			s1_raddr0 <= l2_raddr0;
			s1_raddr1 <= l2_raddr1;
			s1_odd <= l2_odd;

			s1_memodd <= l2_memodd;
			s1_memaddr1 <= l2_memaddr1;
			s1_memaddr2 <= l2_memaddr2;
			s1_regData <= l2_regData;
			s1_postfreeze <= 0;
			s1_savedata0_ <= 0;
			s1_savedata1_ <= 0;
		end
		if(s1_freeze & ~s1_wipe) begin
			s1_postfreeze <= 1;
			s1_savedata0_ <= s1_usedata0_;
			s1_savedata1_ <= s1_usedata1_;
		end
		if(s1_wipe) begin
			s1_enable <= 0;
			s1_PC <= 0;
			s1_raddr0 <= 0;
			s1_raddr1 <= 0;
			s1_odd <= 0;

			s1_memodd <= 0;
			s1_memaddr1 <= 0;
			s1_memaddr2 <= 0;
			s1_regData <= 0;

			s1_postfreeze <= 0;
			s1_savedata0_ <= 0;
			s1_savedata1_ <= 0;
		end
    end	

	////////////
	// Store2 //
	////////////
		reg s2_enable = 0;
		reg [15:0]s2_PC;

		reg [15:1]s2_memaddr2;

		reg [15:0]s2_stData2;

		//store 2
		wire s2_active = s2_enable;
		wire s2_wen = s2_active;
		wire [15:1]s2_waddr = s2_memaddr2;
		wire [15:0]s2_wdata = s2_stData2;

		//wipe
			//access s2_memaddr2;
		//freeze
			// Store1

    always @(posedge clk) begin
		s2_enable <= s1_active & s1_memodd;
		s2_PC <= s1_PC;

		s2_memaddr2 <= s1_memaddr2;

		s2_stData2 <= s1_stData2;
    end

	///////////////////
	// Final Assigns //
	///////////////////
	assign raddr0_ = 
		{15{l1_addr0En}} & l1_addr0 |
		{15{~l1_addr0En & f1_addr0En}} & f1_addr0;
	assign raddr1_ =
		{15{l1_addr1En}} & l1_addr1 |
		{15{~l1_addr1En & f1_addr1En}} & f1_addr1;
	assign wen = (s2_wen | s1_wen);
	assign waddr =
		{15{s2_wen}} & s2_waddr |
		{15{s1_wen & ~s2_wen}} & s1_waddr;
	assign wdata =
		{16{s2_wen}} & s2_wdata |
		{16{s1_wen & ~s2_wen}} & s1_wdata;

	assign regA = r_regA;
	assign regB = r_regB;
	assign regWEn = (l3_regWEn | e_rregWEn) & ~(regW == 0);
	wire regPrint = (l3_regWEn | e_rregWEn) & (regW == 0);
	assign regW = 
		{4{l3_regWEn}} & l3_regW |
		{4{~l3_regWEn & e_rregWEn}} & e_regW;
	assign regWData = 
		{16{l3_regWEn}} & l3_regWData |
		{16{~l3_regWEn & e_rregWEn}} & e_regWData;
	
	always @(posedge clk) begin
		if(regPrint)begin
			$write("%c", regWData[7:0]);		
		end
    end

	wire wipe_s1 = ~e_willJmp & 
		s1_wipe & s1_enable;
	wire wipe_l3 = ~e_willJmp & ~wipe_s1 & 
		l3_wipe & l3_enable;
	wire wipe_l2 = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & 
		l2_wipe & l2_enable;
	wire wipe_l1 = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & ~wipe_l2 & 
		l1_wipe & l1_enable;
	wire wipe_e = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & ~wipe_l2 & ~wipe_l1 & 
		e_wipe & e_enable;
	wire wipe_d = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & ~wipe_l2 & ~wipe_l1 & ~wipe_e & 
		d_wipe & d_enable;
	wire wipe_f2 = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & ~wipe_l2 & ~wipe_l1 & ~wipe_e & ~wipe_d &
		f2_wipe & f2_enable;
	wire wipe_f1 = ~e_willJmp & ~wipe_s1 & ~wipe_l3 & ~wipe_l2 & ~wipe_l1 & ~wipe_e & ~wipe_d & ~wipe_f2 &
		f1_wipe & f1_enable;
	
	wire [15:0]wipePC = 
		{16{e_willJmp}} & e_jmpPC |
		{16{wipe_s1}} & s1_PC |
		{16{wipe_l3}} & l3_PC |
		{16{wipe_l2}} & l2_PC |
		{16{wipe_l1}} & l1_PC|
		{16{wipe_e}} & e_PC |
		{16{wipe_d}} & d_PC |
		{16{wipe_f2}} & f2_PC |
		{16{wipe_f1}} & f1_PC;  

endmodule
