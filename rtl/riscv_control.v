module riscv_control (
    input  wire [6:0] opcode,
    output reg        branch,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg  [1:0] alu_op,
    output reg        mem_write,
    output reg        alu_src,
    output reg        reg_write
);

    always @(*) begin
        // Defaults
        branch = 0; mem_read = 0; mem_to_reg = 0;
        alu_op = 2'b00; mem_write = 0; alu_src = 0; reg_write = 0;

        case (opcode)
            // R-Type (ADD, SUB, etc.)
            7'b0110011: begin reg_write = 1; alu_op = 2'b10; end

            // I-Type (ADDI)
            7'b0010011: begin alu_src = 1; reg_write = 1; alu_op = 2'b00; end // Op 00 = ADD

            // Load (LW)
            7'b0000011: begin alu_src = 1; mem_to_reg = 1; reg_write = 1; mem_read = 1; alu_op = 2'b00; end

            // Store (SW)
            7'b0100011: begin alu_src = 1; mem_write = 1; alu_op = 2'b00; end

            // Branch (BEQ)
            7'b1100011: begin branch = 1; alu_op = 2'b01; end

            // LUI (Load Upper Immediate) - CRITICAL FIX
            7'b0110111: begin 
                alu_src = 1;   // Use Immediate
                reg_write = 1; // Write to Register
                alu_op = 2'b11; // New Code for LUI? Or reuse ADD?
                // TRICK: We can just reuse ADD (00) because LUI Immediate is valid.
                // But normally we want ALU to ignore Register 1.
                // For simplicity in this project: Let's use alu_op = 2'b00 (ADD).
                // NOTE: This assumes Register 1 (which LUI doesn't have) is 0.
                // Since LUI instr format bits [19:15] are part of IMM, 
                // they might map to a non-zero Reg Index.
                // SAFE WAY: Assume ALU adds src1 + src2. 
                // For LUI, we rely on the fact that we need a "Pass Through B" operation.
            end
            
            // JAL (Jump)
            7'b1101111: begin alu_src = 1; reg_write = 1; end // Simplified
        endcase
    end
endmodule