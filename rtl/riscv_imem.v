module riscv_imem (
    input  wire [31:0] a,
    output wire [31:0] rd
);
    // Declare memory array "mem"
    reg [31:0] mem [0:63]; // 64 Words

    // Initial block for testing (Optional, handled by testbench usually)
    initial begin
        mem[0] = 32'h00000013; // NOP
    end

    // Read Logic (Word Aligned)
    assign rd = mem[a[31:2]]; 
endmodule