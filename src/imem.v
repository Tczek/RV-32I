module  imem #(
    parameter MEMORY_DEPTH = 256
) (
    input wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:MEMORY_DEPTH-1];

    initial $readmemh("testbench/hex/program.hex", mem);
    assign instr = mem[addr[31:2]];

endmodule
