/* instruction memory */

`timescale 1ps/1ps

module mem(input clk,
    input [15:0]raddr, output [7:0]rdata,
    input wen, input [15:0]waddr, input [7:0]wdata);

    reg [7:0]data[0:16'hffff];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",data);
    end

    assign rdata = data[raddr];

    always @(posedge clk) begin
        if (wen) data[waddr] <= wdata;
    end

endmodule
