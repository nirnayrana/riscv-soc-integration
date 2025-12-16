module riscv_hazard_unit (
    // Inputs for Load-Use Hazard Detection
    input  wire [4:0] if_id_rs1,      // Source Reg 1 from Decode Stage
    input  wire [4:0] if_id_rs2,      // Source Reg 2 from Decode Stage
    input  wire [4:0] id_ex_rd,       // Destination Reg from Execute Stage
    input  wire       id_ex_mem_read, // Is the instruction in EX a Load? (LW)

    // Input for UART/SoC Stall (The "Super Stall")
    input  wire       uart_stall,     // From the APB Bridge

    // Outputs to Freeze the Pipeline
    output reg        pc_write,       // Enable PC Update
    output reg        if_id_write,    // Enable IF/ID Register Update
    output reg        control_flush,  // Flush the ID/EX Control signals (Insert Bubble)
    output reg        pipeline_freeze // Freeze EX/MEM and MEM/WB registers
);

    always @(*) begin
        // Defaults: Everything runs normally
        pc_write        = 1'b1;
        if_id_write     = 1'b1;
        control_flush   = 1'b0; // 0 means pass control signals normally
        pipeline_freeze = 1'b0;

        // ---------------------------------------------
        // Priority 1: EXTERNAL STALL (UART is Busy)
        // ---------------------------------------------
        // If the UART says "Wait", we freeze the ENTIRE pipeline exactly as is.
        if (uart_stall) begin
            pc_write        = 1'b0; // Freeze PC
            if_id_write     = 1'b0; // Freeze Fetch/Decode
            control_flush   = 1'b0; // Don't flush! Just pause state.
            pipeline_freeze = 1'b1; // Freeze the back-end registers too
        end
        
        // ---------------------------------------------
        // Priority 2: INTERNAL STALL (Load-Use Hazard)
        // ---------------------------------------------
        // Only check this if UART is NOT stalling.
        // Condition: Instruction in EX is LW, and it targets a reg needed by ID.
        else if (id_ex_mem_read && 
                ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            
            pc_write      = 1'b0; // Freeze PC (Don't fetch next)
            if_id_write   = 1'b0; // Freeze Decode (Retry current instr)
            control_flush = 1'b1; // Insert Bubble (Turn current Decode into NOP)
            // Note: Back-end (EX/MEM/WB) keeps moving to drain the pipe.
        end
    end

endmodule