`timescale 1ns/1ps
module tb_regfile;
    reg        clk=0,we;
    reg  [4:0] waddr,raddr1,raddr2;
    reg  [31:0]wdata;
    wire [31:0]rdata1,rdata2;
    regfile dut(.clk(clk),.we(we),.waddr(waddr),.wdata(wdata),.raddr1(raddr1),.rdata1(rdata1),.raddr2(raddr2),.rdata2(rdata2));
    always #5 clk=~clk;
    integer errors=0;
    task chk(input [31:0]a,input [31:0]e);
        if(a!==e)begin $display("FAIL got=%0h exp=%0h",a,e);errors=errors+1;end
        else $display("ok   %0h",a);
    endtask
    initial begin
        // write 42 into x1
        we=1;waddr=5'd1;wdata=32'd42;raddr1=5'd1;raddr2=5'd0;
        @(posedge clk);#1;chk(rdata1,32'd42);  // x1=42

        // write 99 into x5
        waddr=5'd5;wdata=32'd99;raddr1=5'd5;
        @(posedge clk);#1;chk(rdata1,32'd99);  // x5=99

        // x0 always reads 0 even if written
        waddr=5'd0;wdata=32'hDEAD;raddr1=5'd0;
        @(posedge clk);#1;chk(rdata1,32'd0);   // x0=0

        // simultaneous read x1 and x5
        we=0;raddr1=5'd1;raddr2=5'd5;#1;
        chk(rdata1,32'd42);chk(rdata2,32'd99);

        if(errors==0) $display("ALL TESTS PASSED"); else $display("%0d FAILED",errors);
        $finish;
    end
endmodule