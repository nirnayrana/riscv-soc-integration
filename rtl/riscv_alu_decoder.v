module riscv_alu_decoder (
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire funct7,
    input wire [6:0] op,
    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            // 1. LW, SW, ADDI -> Force ADD
            // Your ALU_ADD is 0000
            2'b00: alu_ctrl = 4'b0000; 

            // 2. BEQ (Branch) -> Force SUB
            // Your ALU_SUB is 0001
            2'b01: alu_ctrl = 4'b0001; 

            // 3. R-Type (Depends on funct3)
            2'b10: begin
                case (funct3)
                    3'b000: begin // ADD or SUB
                        if (funct7) alu_ctrl = 4'b0001; // SUB
                        else        alu_ctrl = 4'b0000; // ADD
                    end
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b001: alu_ctrl = 4'b0101; // SLL
                    3'b101: alu_ctrl = (funct7) ? 4'b0111 : 4'b0110; // SRA or SRL
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule