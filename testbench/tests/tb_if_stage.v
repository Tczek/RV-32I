`timescale 1ns/1ps
module tb_if_stage;
    reg        clk=0, rst=1;
    reg [31:0] pc_next;
    wire[31:0] pc, instr;

    if_stage dut(.clk(clk),.rst(rst),.pc_next(pc_next),.pc(pc),.instr(instr));
    always #5 clk=~clk;

    integer errors=0;
    task check(input [31:0] epc, input [31:0] einstr);
        if(pc!==epc||instr!==einstr)begin
            $display("FAIL pc=%0h instr=%0h (exp pc=%0h instr=%0h)",pc,instr,epc,einstr);
            errors=errors+1;
        end else $display("ok   pc=%0h instr=%0h",pc,instr);
    endtask

    initial begin
        pc_next=0; @(posedge clk); #1; check(32'h0,32'h00500093); // reset, fetch instr 0
        rst=0;
        pc_next=32'h4; @(posedge clk); #1; check(32'h4,32'h00A00113);
        pc_next=32'h8; @(posedge clk); #1; check(32'h8,32'h002081B3);
        pc_next=32'hC; @(posedge clk); #1; check(32'hC,32'h00000013);
        if(errors==0) $display("ALL TESTS PASSED"); else $display("%0d FAILED",errors);
        $finish;
    end
endmodule