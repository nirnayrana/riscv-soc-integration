module riscv_soc (
    input wire clk,
    input wire rst_n,
    output wire tx_serial
);

    // Internal Wires
    wire [31:0] cpu_pc_addr, cpu_instr;
    wire [31:0] cpu_data_addr, cpu_wdata, cpu_rdata_raw;
    wire cpu_mem_write, cpu_mem_read;
    wire stall_signal;
    wire [31:0] dmem_rdata;
    reg  [31:0] final_cpu_rdata;

    // APB Wires
    wire [31:0] paddr, pwdata, prdata;
    wire psel, penable, pwrite, pready;

    // Address Decoding
    wire is_peripheral = (cpu_data_addr[31:16] == 16'hFFFF);

    // MUX: CPU Read Data (RAM vs. Peripheral)
    always @(*) begin
        if (is_peripheral) final_cpu_rdata = 0; // Or from APB if reading supported
        else               final_cpu_rdata = dmem_rdata;
    end

    // 1. The CPU Core (External Interface)
    riscv_top cpu (
        .clk(clk),
        .rst_n(rst_n),
        .stall_in(stall_signal),
        .pc(cpu_pc_addr),       // Instruction Address
        .instr(cpu_instr),      // Instruction Data
        .alu_result(cpu_data_addr), // Data Address
        .write_data(cpu_wdata),     // Data to Write
        .read_data(final_cpu_rdata),// Data Read Input
        .mem_write(cpu_mem_write),
        .mem_read(cpu_mem_read)
    );

    // 2. Instruction Memory (Now lives in SoC)
    riscv_imem IMEM (
        .a(cpu_pc_addr), .rd(cpu_instr)
    );

    // 3. Data Memory (RAM)
    riscv_dmem ram (
        .clk(clk),
        .we(cpu_mem_write && !is_peripheral),
        .a(cpu_data_addr),
        .wd(cpu_wdata),
        .rd(dmem_rdata)
    );

    // 4. APB Bridge
    apb_master bridge (
        .clk(clk),
        .rst_n(rst_n),           // FIXED: was .rst
        .cpu_addr(cpu_data_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_mem_write(cpu_mem_write && is_peripheral),
        .cpu_mem_read(cpu_mem_read && is_peripheral),
        .cpu_rdata(), 
        .cpu_stall(stall_signal),
        .paddr(paddr), .pwdata(pwdata), .pwrite(pwrite),
        .psel(psel), .penable(penable), .prdata(prdata), .pready(pready)
    );

    // 5. UART Wrapper
    apb_uart uart_device (
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr), .pwdata(pwdata), .psel(psel),
        .penable(penable), .pwrite(pwrite), .pready(pready),
        .prdata(prdata), .tx_serial(tx_serial)
    );

endmodule