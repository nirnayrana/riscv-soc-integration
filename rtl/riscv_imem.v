module riscv_imem (
    input wire [31:0] a,
    output wire [31:0] rd
);
    reg [31:0] RAM [63:0];
    initial begin
        RAM[0] = 32'h00500093; 
        RAM[1] = 32'h00800113; 
        RAM[2] = 32'h002081b3; 
        RAM[3] = 32'h00900213; 
        RAM[4] = 32'h003222b3;
        RAM[5] = 32'h00028463; 
        RAM[6] = 32'h00600313; 
        RAM[7] = 32'h006181b3; 
        RAM[8] = 32'h00000000;
    end
    assign rd = RAM[a[31:2]]; 
endmodule