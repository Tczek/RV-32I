module regfile(
    input wire clk,
    input wire we,
    input wire [31:0] wdata,
    input wire [4:0] waddr,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2
);
    reg [31:0] regs [31:0] ;
    integer i;
    initial for (i = 0;i<=31 ;i=i+1 ) regs[i]=32'b0; // power-on reset all zero

    // synchronous write — x0 stays zero (waddr==0 is ignored)
    always @(posedge clk) if (we && waddr != 5'd0) regs[waddr] <= wdata;

    // asynchronous reads — x0 always returns 0
    assign rdata1 = (raddr1 == 5'd0) ? 32'd0: regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0 ) ? 32'd0: regs[raddr2];


endmodule