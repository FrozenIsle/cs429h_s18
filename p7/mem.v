/* instruction memory */

`timescale 1ps/1ps

module mem(input clk,
    input [15:0]raddr0, output [15:0]rdata0,
    input wen0, input [15:0]waddr0, input [15:0]wdata0,
	input [15:0] ldaddr, output [15:0]lddata);

    reg [7:0]data[0:16'hffff];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",data);
    end

	wire [16:0]raddr1;
	assign raddr1 = {1'b0, raddr0}+1;

	wire [16:0] ldaddr1;
	assign ldaddr1 = {1'b0, ldaddr} +1;

	wire [16:0] waddr1;
	assign waddr1 = {1'b0, waddr0} +1;

	wire [7:0]rdataone = data[raddr0];
	wire [7:0]rdatatwo = data[raddr1[15:0]];
	assign rdata0 = {rdataone, rdatatwo};

	wire [7:0]lddataone = data[ldaddr];
	wire [7:0]lddatatwo = data[ldaddr1[15:0]];
	assign lddata = {lddataone, lddatatwo};

    always @(posedge clk) begin
//	$write("%d ",raddr0);
//	$write("%d ",raddr1);
//	$write("%d ",ldaddr);
//	$write("%b\n",ldaddr1);
		
		if(wen0 == 0) begin	
//	$write("dataone %b\n", data[16'b1111111100001100]);
//	$write("datatwo %b\n", data[16'b1111111100001101]);
//	$write("data3 %b\n", ldaddr);
//	$write("ld1 = %b\n",lddataone);
//	$write("ld2 = %b\n",lddatatwo);
		end
        if (wen0) begin
//		$write("write\n");
//		$write("add = %b\n", waddr0);
//		$write("data = %b\n", wdata0[7:0]);
		data[waddr0] <= wdata0[15:8];
		data[waddr1[15:0]] <= wdata0[7:0];
		end
    end

endmodule
