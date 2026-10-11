
module if_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,  
    output wire [31:0] pc,        
    output wire [31:0] instr);

    pc   pc_reg  (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));
    imem imem_mod(.addr(pc), .instr(instr));
endmodule