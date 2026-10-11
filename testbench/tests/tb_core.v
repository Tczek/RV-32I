// tb_riscv_core.v — Testbench for the complete single-cycle RV32I core
// Loads program.hex, runs for 50 cycles, checks mem[0] == 15
`timescale 1ns/1ps
module tb_riscv_core;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk; // 100 MHz

    rv32i_core dut (.clk(clk), .rst(rst));

    integer i;
    reg [31:0] result;
    initial begin
        // Load the sum 1..5 program from hex file
        #1;
        $readmemh("../hex/program2.hex", dut.imem0.mem);

        $dumpfile("tb_riscv_core.vcd");
        $dumpvars(0, tb_riscv_core);

        // Release reset after 2 cycles
        repeat(2) @(posedge clk);
        rst = 0;

        // Run for enough cycles for the loop to complete
        // (9 instructions × loop 5 times + setup = ~30 cycles)
        repeat(50) @(posedge clk);
        #1;

        // Check: memory address 0 should contain 15 (sum 1..5)
        // DMEM is byte-addressed; word at addr 0 = bytes [3:0]
        begin
            result = {dut.dmem0.mem[3], dut.dmem0.mem[2],
                      dut.dmem0.mem[1], dut.dmem0.mem[0]};
            if (result === 32'd15)
                $display("PASS: sum(1..5) = %0d stored at mem[0]", result);
            else
                $display("FAIL: mem[0] = %0d (expected 15)", result);
        end

        //dump register file
        $display("--- Register File Snapshot ---");
        for (i = 0; i < 8; i = i+1)
            $display("  x%0d = %0d", i, dut.rf.regs[i]);

        $finish;
    end
endmodule