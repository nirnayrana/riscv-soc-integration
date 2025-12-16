`timescale 1ns/1ns
module riscv_pipeline_top (
    input wire clk,
    input wire rst,
    
    // --- SoC INTERFACE ---
    input  wire        uart_stall,   
    output wire [31:0] dmem_addr,    
    output wire [31:0] dmem_wdata,   
    output wire        dmem_wen,     
    input  wire [31:0] dmem_rdata    
);

    // --- FORWARD DECLARATIONS ---
    wire [4:0]  rd_M, rd_W; 
    wire        RegWrite_M, RegWrite_W;
    wire [31:0] ALUResult_M, Result_W;
    wire        Jump_M; // Needed for PC Logic
    
    // --- HAZARD SIGNALS ---
    wire pc_write;
    wire if_id_write;
    wire control_flush;
    wire pipeline_freeze;

    // --- STAGE 1: FETCH (F) ---
    wire [31:0] PC_F, PC_Next_F, PC_Plus4_F, PC_Target_Decision;
    wire [31:0] Instr_F;
    wire        PCSrc_M; 
    wire [31:0] PCTarget_M; 

    // PC Mux: If Stall (pc_write=0), keep the OLD PC.
    wire [31:0] PC_Final_Next = (pc_write) ? PC_Next_F : PC_F;

    riscv_pc PC_Module (
        .clk(clk),
        .rst(rst),
        .pc_next(PC_Final_Next),
        .pc_current(PC_F)
    );

    assign PC_Plus4_F = PC_F + 4;
    // Branch Mux: If Branch Taken OR Jump Taken -> Use Target
    assign PC_Target_Decision = (PCSrc_M) ? PCTarget_M : PC_Plus4_F;
    assign PC_Next_F = PC_Target_Decision; 

    riscv_imem IMEM (
        .a(PC_F),
        .rd(Instr_F)
    );

    // --- PIPELINE REG: IF / ID ---
    wire [31:0] Instr_D, PC_D;
    
    riscv_pipe_reg #(.N(64)) IF_ID_REG (
        .clk(clk),
        .rst(rst),
        .clear(PCSrc_M),      // Flush if Branch/Jump taken!
        .en(if_id_write),     
        .d({Instr_F, PC_F}), 
        .q({Instr_D, PC_D})  
    );

    // --- STAGE 2: DECODE (D) ---
    wire [6:0] opcode = Instr_D[6:0];
    wire [4:0] rd_D   = Instr_D[11:7];
    wire [2:0] funct3_D = Instr_D[14:12];
    wire [4:0] rs1_D  = Instr_D[19:15];
    wire [4:0] rs2_D  = Instr_D[24:20];
    wire [6:0] funct7_D = Instr_D[31:25];

    wire RegWrite_D, MemtoReg_D, MemWrite_D, ALUSrc_D, Branch_D, MemRead_D, Jump_D;
    wire [1:0] ALUOp_D;

    // ** FIXED PORT NAMES (Lowercase to match riscv_control.v) **
    riscv_control Control_Unit (
        .opcode(opcode),
        .branch(Branch_D),       // Lowercase .branch
        .jump(Jump_D),           // Lowercase .jump
        .mem_read(MemRead_D),    // Lowercase .mem_read
        .mem_to_reg(MemtoReg_D), // Lowercase .mem_to_reg
        .alu_op(ALUOp_D),        // Lowercase .alu_op
        .mem_write(MemWrite_D),  // Lowercase .mem_write
        .alu_src(ALUSrc_D),      // Lowercase .alu_src
        .reg_write(RegWrite_D)   // Lowercase .reg_write
    );

    wire [31:0] RD1_D, RD2_D;
    wire [4:0]  RegWriteAddr_W; 
    wire [31:0] RegWriteData_W; 
    // RegWrite_W declared at top

    // ... inside riscv_pipeline_top.v ...

    riscv_regfile REG_FILE (
        .clk(clk),
        .we3(RegWrite_W), 
        .ra1(rs1_D),
        .ra2(rs2_D),
        .wa3(RegWriteAddr_W),
        .wd3(RegWriteData_W),
        .rd1(RD1_D),
        .rd2(RD2_D)
    );

    wire [31:0] Imm_D;
    riscv_imm_gen IMM_GEN (
        .inst(Instr_D),
        .imm_out(Imm_D)
    );

    // ====================================================
    // *** FIX FOR LUI INSTRUCTION ***
    // LUI should perform (0 + Immediate). 
    // Currently it does (RD1 + Immediate). We must force RD1 to 0.
    // ====================================================
    wire is_lui = (opcode == 7'b0110111);
    
    // If LUI, use 0. Otherwise use Register value.
    wire [31:0] RD1_D_Final = (is_lui) ? 32'b0 : RD1_D; 


    // --- PIPELINE REG: ID / EX ---
    wire [31:0] PC_E, RD1_E, RD2_E, Imm_E;
    wire [4:0]  rd_E, rs1_E, rs2_E; 
    wire [2:0]  funct3_E;
    wire [6:0]  funct7_E;
    wire RegWrite_E, MemtoReg_E, MemWrite_E, ALUSrc_E, Branch_E, MemRead_E, Jump_E;
    wire [1:0] ALUOp_E;

    riscv_pipe_reg #(.N(162)) ID_EX_REG (
        .clk(clk),
        .rst(rst),
        .clear(control_flush | PCSrc_M), 
        .en(~pipeline_freeze),           
        // *** CHANGE RD1_D TO RD1_D_Final BELOW ***
        .d({RegWrite_D, MemtoReg_D, MemWrite_D, Branch_D, Jump_D, MemRead_D, ALUSrc_D, ALUOp_D, 
            PC_D, RD1_D_Final, RD2_D, Imm_D,  // <--- CHANGED THIS INPUT
            rd_D, rs1_D, rs2_D, funct3_D, funct7_D}),                          
        .q({RegWrite_E, MemtoReg_E, MemWrite_E, Branch_E, Jump_E, MemRead_E, ALUSrc_E, ALUOp_E,
            PC_E, RD1_E, RD2_E, Imm_E,
            rd_E, rs1_E, rs2_E, funct3_E, funct7_E})
    );

    // --- STAGE 3: EXECUTE (E) ---
    
    riscv_hazard_unit HAZARD_UNIT (
        .if_id_rs1(rs1_D),
        .if_id_rs2(rs2_D),
        .id_ex_rd(rd_E),
        .id_ex_mem_read(MemRead_E),
        .uart_stall(uart_stall),     
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_flush(control_flush),
        .pipeline_freeze(pipeline_freeze)
    );

    wire [1:0] ForwardA_E, ForwardB_E;

    riscv_forwarding FORWARD_UNIT (
        .rs1_E(rs1_E),
        .rs2_E(rs2_E),
        .rd_M(rd_M),
        .RegWrite_M(RegWrite_M),
        .rd_W(rd_W),
        .RegWrite_W(RegWrite_W),
        .ForwardA(ForwardA_E),
        .ForwardB(ForwardB_E)
    );

    // 3-WAY MUXES
    reg [31:0] SrcA_Forwarded;
    always @(*) begin
        case (ForwardA_E)
            2'b00: SrcA_Forwarded = RD1_E;
            2'b10: SrcA_Forwarded = ALUResult_M;
            2'b01: SrcA_Forwarded = Result_W;
            default: SrcA_Forwarded = RD1_E;
        endcase
    end

    reg [31:0] WriteData_E; 
    always @(*) begin
        case (ForwardB_E)
            2'b00: WriteData_E = RD2_E;
            2'b10: WriteData_E = ALUResult_M;
            2'b01: WriteData_E = Result_W;
            default: WriteData_E = RD2_E;
        endcase
    end

    wire [31:0] SrcB_E = (ALUSrc_E) ? Imm_E : WriteData_E;

    wire [3:0] ALUControl_E;
    riscv_alu_decoder ALU_DEC (
        .alu_op(ALUOp_E),
        .funct3(funct3_E),
        .funct7(funct7_E[5]), 
        .op(Instr_D[6:0]),   
        .alu_ctrl(ALUControl_E)
    );

    wire [31:0] ALUResult_E;
    wire Zero_E;
    
    riscv_alu4b ALU (
        .a(SrcA_Forwarded), 
        .b(SrcB_E),           
        .alu_ctrl(ALUControl_E),
        .result(ALUResult_E),
        .zero(Zero_E)
    );

    wire [31:0] PCTarget_E = PC_E + Imm_E;

    // --- PIPELINE REG: EX / MEM ---
    wire MemtoReg_M, Branch_M, Zero_M;
    wire [31:0] WriteData_M; 
    // rd_M defined at top

    // ** FIXED WIDTH: Changed N to 107 to account for Jump_M **
    riscv_pipe_reg #(.N(107)) EX_MEM_REG (
        .clk(clk),
        .rst(rst),
        .clear(1'b0),
        .en(~pipeline_freeze), 
        .d({RegWrite_E, MemtoReg_E, MemWrite_E, Branch_E, Jump_E, Zero_E,
            ALUResult_E, WriteData_E, PCTarget_E, rd_E}), 
        .q({RegWrite_M, MemtoReg_M, MemWrite_M, Branch_M, Jump_M, Zero_M,
            ALUResult_M, WriteData_M, PCTarget_M, rd_M})
    );

    // --- STAGE 4: MEMORY (M) ---
    
    assign dmem_addr  = ALUResult_M;
    assign dmem_wdata = WriteData_M;
    assign dmem_wen   = MemWrite_M;
    
    wire [31:0] ReadData_M = dmem_rdata;

    // ** LOGIC FIX: Branch if (BEQ taken) OR (Jump taken) **
    assign PCSrc_M = (Branch_M & Zero_M) | Jump_M;

    // --- PIPELINE REG: MEM / WB ---
    wire MemtoReg_W; 
    wire [31:0] ReadData_W;
    wire [31:0] ALUResult_W_Internal;

    riscv_pipe_reg #(.N(71)) MEM_WB_REG (
        .clk(clk),
        .rst(rst),
        .clear(1'b0),
        .en(~pipeline_freeze), 
        .d({RegWrite_M, MemtoReg_M, ALUResult_M, ReadData_M, rd_M}),
        .q({RegWrite_W, MemtoReg_W, ALUResult_W_Internal, ReadData_W, rd_W})
    );

    // --- STAGE 5: WRITEBACK (W) ---
    assign Result_W = (MemtoReg_W) ? ReadData_W : ALUResult_W_Internal;
    assign RegWriteAddr_W = rd_W; 
    assign RegWriteData_W = Result_W;

endmodule