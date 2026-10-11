
module rv32i_core (
    input clk,
    input rst,
    output [31:0] pc_out,
    output [31:0] result_out
);
    // ── 1. Program Counter ────────────────────────────────────────
    reg  [31:0] pc;
    wire [31:0] pc4 = pc + 4;

    // ── 2. Instruction Fetch ──────────────────────────────────────
    wire [31:0] inst;
    imem imem0 (.addr(pc), .instr(inst));

    // ── 3. Instruction Decode ─────────────────────────────────────
    wire [6:0] opcode = inst[6:0];
    wire [4:0] rd     = inst[11:7];
    wire [2:0] funct3 = inst[14:12];
    wire [4:0] rs1    = inst[19:15];
    wire [4:0] rs2    = inst[24:20];
    wire [6:0] funct7 = inst[31:25];

    // ── 4. Control Unit ───────────────────────────────────────────
    wire reg_write, alu_src, mem_read, mem_write, branch, jump;
    wire [1:0] wb_sel;
    wire [2:0] imm_sel;
    wire [3:0] ALUOp;
    control ctrl (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .alu_src(alu_src),
        .mem_read(mem_read), .mem_write(mem_write), .wb_sel(wb_sel),
        .alu_op(ALUOp), .imm_sel(imm_sel), .branch(branch), .jump(jump)
    );

    // ── 5. Register File ──────────────────────────────────────────
    wire [31:0] rdata1, rdata2, wr_data;
    regfile rf (
        .clk(clk), .we(reg_write),
        .raddr1(rs1), .raddr2(rs2), .waddr(rd), .wdata(wr_data),
        .rdata1(rdata1), .rdata2(rdata2)
    );

    // ── 6. Immediate Generator ────────────────────────────────────
    wire [31:0] imm;
    immgen ig (.instr(inst), .imm_sel(imm_sel), .imm(imm));

    // ── 7. ALU ────────────────────────────────────────────────────
    wire [31:0] alu_b = alu_src ? imm : rdata2;
    wire [31:0] alu_out;
    wire        alu_zero, alu_lt, alu_ltu;
    alu alu0 (
        .A(rdata1), .B(alu_b), .alu_sel(ALUOp),
        .alu_out(alu_out), .zero(alu_zero),
        .lt(alu_lt), .ltu(alu_ltu)
    );

    // ── 8. Data Memory ────────────────────────────────────────────
    wire [31:0] dmem_rdata;
    dmem dmem0 (
        .clk(clk), .we(mem_write),
        .addr(alu_out), .wdata(rdata2),
        .funct3(funct3), .rdata(dmem_rdata)
    );

    // ── 9. Branch Unit ────────────────────────────────────────────
    wire        branch_taken;
    wire [31:0] branch_target;
    branch_unit bu (
        .funct3(funct3), .zero(alu_zero),
        .alu_lt(alu_lt), .alu_ltu(alu_ltu),
        .pc(pc), .b_imm(imm),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

    // ── 10. PC Mux ────────────────────────────────────────────────
    wire [31:0] jal_target  = pc + imm;
    wire [31:0] jalr_target = (rdata1 + imm) & ~32'h1;

    wire [31:0] pc_next =
        (branch & branch_taken) ? branch_target :
        (jump && opcode == 7'b1101111) ? jal_target :
        (jump && opcode == 7'b1100111) ? jalr_target : pc4;

    always @(posedge clk or posedge rst)
        if (rst) pc <= 0; else pc <= pc_next;

    // ── 11. Write-Back Mux ────────────────────────────────────────
    assign wr_data = (wb_sel == 2'b01) ? dmem_rdata :
                     (wb_sel == 2'b10) ? pc4 :
                     (wb_sel == 2'b11) ? imm : alu_out;

    assign pc_out = pc;
    assign result_out = wr_data;

endmodule