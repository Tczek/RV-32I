
module alu(
    input wire [31:0]A,
    input wire [31:0]B,
    input wire [3:0]alu_sel,
    output reg [31:0]alu_out,
    output wire zero,
    output wire lt,
    output wire ltu
);
    wire [4:0]shamd = B[4:0];
    assign lt  = ($signed(A) < $signed(B));
    assign ltu = (A < B);

    always @(*) begin
        case(alu_sel)
            4'b0000 :alu_out = A+B; 
            4'b0001 :alu_out = A-B; 
            4'b0010 :alu_out = A&B;
            4'b0011 :alu_out = A|B;
            4'b0100 :alu_out = A^B; //XOR
            4'b0101 : alu_out = {31'd0, lt};  // SLT
            4'b0110 : alu_out = {31'd0, ltu}; // SLTU
            4'b0111 :alu_out = A<<shamd; //SLL
            4'b1000 :alu_out = A>>shamd; //SRL
            4'b1001 :alu_out = ($signed(A))>>>shamd; //SRA
            default: alu_out = 32'd0;
        endcase
    end
    assign zero = (alu_out==32'd0);

endmodule