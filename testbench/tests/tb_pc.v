`timescale 1ns/1ps
module pc_tb()
        reg clk,rst;
        reg [31:0]pc_next;
        wire [31:0]pc;

    pc dut(.clk(clk),.rst(rst),.pc(pc),pc_next(pc_next));

    initial clk = 0;
    always #5 clk = ~clk;

    integer errors = 0;
    task check (input [31:0]exp);
        if (pc!==exp) begin
            $display("FAIL: pc=%0h, expected = %0h", pc,exp);
            errors=errors +1;
        end else begin
            $display("PASED: pc=%0h",pc)
        end
    endtask

    initail begin
        rst=1,@(posedge clk),#1,pc_next = 32'h0;
        check (32'h0);



        rst=0,@(posedge clk),#1,pc_next = 32'h0000_0004;
        check (32'h0000_0004);
        rst = 0, @posedge(clk),#1,pc_next = 32'h0000_0008;
        check (32'h0000_0008);
        rst=0,@(posedge clk), #1,pc_next = 32'h0000_000C;
        check (32'h0000_000C);

        //branch jump
        rst=0,@(posedge clk),#1,pc_next = 32'h0000_1010;
        check (32'h0000_1010);

        rst=1,@(posedge clk,#1,pc_next=32'h0;
        check (32'h0));

        if (errors ==0)$display("ALL TEST PASSED");
        else $display("NUMBER OF ERRORS: %0d", errors)
        $finish

    end
endmodule


