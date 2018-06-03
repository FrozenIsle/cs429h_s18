module counter(input isHalt, input clk);

    reg [31:0] count = 0;

    always @(posedge clk) begin
        if (isHalt) begin
            $finish;
        end
        if (count == 100000) begin
            $display("ran for 100000 cycles");
            $finish;
        end
        count <= count + 1;
    end

endmodule
