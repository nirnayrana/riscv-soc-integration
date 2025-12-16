module riscv_forwarding (
    input wire [4:0] rs1_E,      // Source Register 1 (Execute Stage)
    input wire [4:0] rs2_E,      // Source Register 2 (Execute Stage)
    input wire [4:0] rd_M,       
    input wire RegWrite_M,
    input wire [4:0] rd_W,
    input wire RegWrite_W,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);
    always @(*) begin
        ForwardA = 2'b00; // Default: Use value from Register File
        if (RegWrite_M && (rd_M != 0) && (rd_M == rs1_E)) begin
            ForwardA = 2'b10;
        end
        else if (RegWrite_W && (rd_W != 0) && (rd_W == rs1_E)) begin
            ForwardA = 2'b01;
        end
        ForwardB = 2'b00; // Default
        if (RegWrite_M && (rd_M != 0) && (rd_M == rs2_E)) begin
            ForwardB = 2'b10;
        end
        else if (RegWrite_W && (rd_W != 0) && (rd_W == rs2_E)) begin
            ForwardB = 2'b01;
        end
    end
endmodule