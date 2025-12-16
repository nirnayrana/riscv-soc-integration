`timescale 1ns/1ns
module riscv_top (
    input wire clk,
    input wire rst_n,         // Changed from rst to standard rst_n
    input wire stall_in,

    // Instruction Memory Interface
    output wire [31:0] pc,    // Address to fetch
    input  wire [31:0] instr, // Instruction coming back

    // Data Memory Interface
    output wire [31:0] alu_result,      // Address
    output wire [31:0] write_data,      // Data to write
    input  wire [31:0] read_data,       // Data read back
    output wire        mem_write,
    output wire        mem_read
);

    // Internal Wires
    wire [31:0] pc_next, pc_plus4, pc_branch;
    wire [31:0] imm_ext, alu_input_b;
    wire [31:0] result_mux; // Writeback data
    
    // Control Signals
    wire branch, mem_to_reg, alu_src, reg_write;
    wire [1:0] alu_op;
    wire [3:0] alu_ctrl;
    wire alu_zero;

    // 1. Fetch Stage
    wire pcsrc = branch & alu_zero;
    assign pc_plus4 = pc + 4;
    assign pc_branch = pc + imm_ext;
    assign pc_next = (pcsrc) ? pc_branch : pc_plus4;

    riscv_pc PC (
        .clk(clk), .rst(rst_n), .stall(stall_in), // Updated port names
        .next_pc(pc_next), .pc(pc)
    );

    // NOTE: IMEM is removed! It is now external.

    // 2. Decode Stage
    riscv_control CONTROL (
        .opcode(instr[6:0]), 
        .branch(branch), .mem_read(mem_read), .mem_to_reg(mem_to_reg), 
        .alu_op(alu_op), .mem_write(mem_write), .alu_src(alu_src), .reg_write(reg_write)
    );

    riscv_regfile REG_FILE (
        .clk(clk), .we(reg_write), 
        .a1(instr[19:15]), .a2(instr[24:20]), .a3(instr[11:7]), 
        .wd3(result_mux), 
        .rd1(), // We don't use rd1 directly in top output, but ALU needs it
        .rd2(write_data) // Connected to output!
    );
    
    // We need to fetch register 1 data for ALU
    wire [31:0] src_a, src_b_reg;
    assign src_a = REG_FILE.rd1; // Implicit connection if Regfile ports match
    // Or better, instantiate explicitly if your regfile uses specific port names:
    // Ensure your RegFile instantiation matches your RegFile module definition!

    riscv_imm_gen IMM_GEN ( .instruction(instr), .imm_out(imm_ext) );

    // 3. Execute Stage
    assign alu_input_b = (alu_src) ? imm_ext : write_data;

    riscv_alu_decoder ALU_DEC (
        .alu_op(alu_op), .funct3(instr[14:12]), .funct7(instr[30]), .op(instr[6:0]),
        .alu_ctrl(alu_ctrl)
    );

    // Detect LUI opcode (0110111)
    wire is_lui = (instr[6:0] == 7'b0110111);

    // MUX: If LUI, force Input A to 0. Otherwise use Register 1.
    wire [31:0] alu_input_a = (is_lui) ? 32'b0 : REG_FILE.rd1;

    riscv_alu4b ALU (
        .a(alu_input_a), // <--- CONNECT THE NEW WIRE
        .b(alu_input_b), 
        .alu_ctrl(alu_ctrl), 
        .result(alu_result), 
        .zero(alu_zero)
    );

    // 4. Memory Stage (External)
    // DMEM is removed! It is now external.

    // 5. Writeback Stage
    assign result_mux = (mem_to_reg) ? read_data : alu_result;

endmodule