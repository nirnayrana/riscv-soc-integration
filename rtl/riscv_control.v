module riscv_control (
    input  wire [6:0] opcode,
    output reg        branch,
    output reg        jump,      // NEW: Explicit Jump Signal
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg  [1:0] alu_op,
    output reg        mem_write,
    output reg        alu_src,
    output reg        reg_write
);

    always @(*) begin
        // Defaults
        branch = 0; jump = 0; mem_read = 0; mem_to_reg = 0;
        alu_op = 2'b00; mem_write = 0; alu_src = 0; reg_write = 0;

        case (opcode)
            // R-Type (ADD, SUB)
            7'b0110011: begin reg_write = 1; alu_op = 2'b10; end

            // I-Type (ADDI)
            7'b0010011: begin alu_src = 1; reg_write = 1; alu_op = 2'b00; end

            // Load (LW)
            7'b0000011: begin alu_src = 1; mem_to_reg = 1; reg_write = 1; mem_read = 1; alu_op = 2'b00; end

            // Store (SW)
            7'b0100011: begin alu_src = 1; mem_write = 1; alu_op = 2'b00; end

            // Branch (BEQ)
            7'b1100011: begin branch = 1; alu_op = 2'b01; end

            // LUI (Load Upper Immediate)
            7'b0110111: begin alu_src = 1; reg_write = 1; alu_op = 2'b00; end

            // JAL (Jump)
            7'b1101111: begin 
                jump = 1;       // NEW: Activate Jump
                alu_src = 1; 
                reg_write = 1; 
                alu_op = 2'b00; // ADD (PC + Imm)
            end
        endcase
    end
endmodule