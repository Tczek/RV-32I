module rv32i_core (
    input  wire        clk,
    input  wire        rst,

    // Interfejs Pamięci Instrukcji
    output reg  [31:0] pc,
    input  wire [31:0] instr,

    // Interfejs Pamięci Danych
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire [31:0] mem_rdata,
    output wire        mem_we
);

    // Sygnały wewnętrzne
    wire [31:0] pc_next, pc_plus4, pc_target;
    wire [31:0] rs1_data, rs2_data, imm;
    wire [31:0] alu_b, alu_result;
    reg  [31:0] write_back_data;
    wire        zero, take_branch;

    // Sygnały sterujące
    wire       reg_write, alu_src, branch, jump;
    wire [1:0] result_src;
    wire [3:0] alu_ctrl;

    // --- Program Counter (PC) ---
    assign pc_plus4    = pc + 32'd4;
    assign pc_target   = pc + imm;
    assign take_branch = (branch & zero) | jump;
    assign pc_next     = take_branch ? pc_target : pc_plus4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    // --- Instancje Modułów ---
    control_unit ctrl (
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_we),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl)
    );

    reg_file rf (
        .clk(clk),
        .we(reg_write),
        .rs1_addr(instr[19:15]),
        .rs2_addr(instr[24:20]),
        .rd_addr(instr[11:7]),
        .rd_data(write_back_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    imm_gen ig (
        .instr(instr),
        .imm(imm)
    );

    // Multiplexer źródła B dla ALU
    assign alu_b = alu_src ? imm : rs2_data;

    alu alu_unit (
        .a(rs1_data),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    // Multiplexer zapisu do rejestru (Write-Back)
    always @(*) begin
        case (result_src)
            2'b00: write_back_data = alu_result;
            2'b01: write_back_data = mem_rdata;
            2'b10: write_back_data = pc_plus4;
            default: write_back_data = alu_result;
        endcase
    end

    // Interfejs pamięci danych
    assign mem_addr  = alu_result;
    assign mem_wdata = rs2_data;

endmodule

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    assign zero = (result == 32'b0);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                                    // ADD / ADDI
            4'b0001: result = a - b;                                    // SUB
            4'b0010: result = a & b;                                    // AND / ANDI
            4'b0011: result = a | b;                                    // OR / ORI
            4'b0100: result = a ^ b;                                    // XOR / XORI
            4'b0101: result = a << b[4:0];                              // SLL / SLLI
            4'b0110: result = a >> b[4:0];                              // SRL / SRLI
            4'b0111: result = $unsigned($signed(a) >>> b[4:0]);         // SRA / SRAI
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0; // SLT / SLTI
            4'b1001: result = (a < b) ? 32'b1 : 32'b0;                   // SLTU / SLTIU
            default: result = 32'b0;
        endcase
    end
endmodule

module reg_file (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] registers [31:0];

    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

    always @(posedge clk) begin
        if (we && (rd_addr != 5'b0)) begin
            registers[rd_addr] <= rd_data;
        end
    end
endmodule

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);
    always @(*) begin
        case (instr[6:0])
            7'b0010011, // I-type (ALU)
            7'b0000011, // I-type (Load)
            7'b1100111: // I-type (JALR)
                imm = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: // S-type (Store)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // B-type (Branch)
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

            7'b0110111, // U-type (LUI)
            7'b0010111: // U-type (AUIPC)
                imm = {instr[31:12], 12'b0};

            7'b1101111: // J-type (JAL)
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            default: imm = 32'b0;
        endcase
    end
endmodule

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_write,
    output reg  [1:0] result_src,
    output reg        branch,
    output reg        jump,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b001: alu_ctrl = 4'b0101; // SLL
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    3'b011: alu_ctrl = 4'b1001; // SLTU
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA : SRL
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b111: alu_ctrl = 4'b0010; // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0010011: begin // I-type (ALU)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTIU
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b001: alu_ctrl = 4'b0101; // SLLI
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // SRAI : SRLI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0000011: begin // Load (LW)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                result_src = 2'b01;
                alu_ctrl   = 4'b0000;
            end

            7'b0100011: begin // Store (SW)
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            7'b1100011: begin // Branch (BEQ)
                branch   = 1'b1;
                alu_ctrl = 4'b0001;
            end

            7'b1101111: begin // JAL
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;
            end

            default: begin
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                mem_write  = 1'b0;
                result_src = 2'b00;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_ctrl   = 4'b0000;
            end
        endcase
    end
endmodule
