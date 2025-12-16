`timescale 1ns/1ns

module riscv_soc_top (
    input  wire clk,
    input  wire rst_n,     // Active Low Reset
    output wire tx_serial  // UART Output
);

    // --- Signals ---
    wire rst = ~rst_n;     // CPU expects Active High Reset
    
    // CPU Interface
    wire [31:0] cpu_addr;
    wire [31:0] cpu_wdata;
    wire        cpu_wen;
    wire [31:0] cpu_rdata;
    wire        uart_stall; // The signal that freezes the pipeline

    // Memory Interface
    wire [31:0] ram_rdata;
    
    // APB Bridge Interface
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        apb_psel;
    wire        apb_penable;
    wire [31:0] apb_paddr;
    wire        apb_pwrite;
    wire [31:0] apb_pwdata;

    // UART Interface
    wire uart_pwrite;
    wire uart_psel;
    wire uart_penable;
    wire [31:0] uart_prdata;
    wire uart_pready;

    // =========================================================
    // 1. ADDRESS DECODING (The Traffic Cop)
    // =========================================================
    // RAM Range:  0x0000_0000 - 0x0000_00FF
    // UART Range: 0xFFFF_0000 - 0xFFFF_00FF
    
    wire is_peripheral = (cpu_addr[31:16] == 16'hFFFF); 
    wire is_ram        = (cpu_addr[31:16] == 16'h0000);

    // =========================================================
    // 2. STALL LOGIC (The "Stop Button")
    // =========================================================
    // If we are talking to a peripheral, and it is NOT ready, we stall.
    // Note: APB is 2 cycles minimum. We stall until PREADY goes high.
    assign uart_stall = is_peripheral & cpu_wen & ~apb_pready;

    // =========================================================
    // 3. READ DATA MUX
    // =========================================================
    // If CPU reads, who answers? RAM or APB?
    assign cpu_rdata = (is_peripheral) ? apb_prdata : ram_rdata;

    // =========================================================
    // 4. MODULE INSTANTIATION
    // =========================================================

    // --- PIPELINED CPU ---
    riscv_pipeline_top uut_cpu (
        .clk(clk),
        .rst(rst),
        .uart_stall(uart_stall),  // <--- CONNECTED HERE
        .dmem_addr(cpu_addr),
        .dmem_wdata(cpu_wdata),
        .dmem_wen(cpu_wen),
        .dmem_rdata(cpu_rdata)
    );

    // --- DATA MEMORY (RAM) ---
    // Note: Address needs to be word aligned for some RAMs, 
    // but your module likely takes the raw address.
    riscv_dmem u_dmem (
        .clk(clk),
        .we(cpu_wen & is_ram), // Only write if address is RAM
        .a(cpu_addr),
        .wd(cpu_wdata),
        .rd(ram_rdata)
    );

    // --- APB MASTER BRIDGE ---
    apb_master u_bridge (
        .clk(clk),
        .rst_n(rst_n),
        .start(is_peripheral & cpu_wen), // Start transaction if writing to Periph
        .addr(cpu_addr),
        .wdata(cpu_wdata),
        .write(cpu_wen),
        .ready(apb_pready),      // Output: Tells us when done
        .prdata(apb_prdata),     // Output: Data from slave
        // APB Lines
        .psel(apb_psel),
        .penable(apb_penable),
        .paddr(apb_paddr),
        .pwrite(apb_pwrite),
        .pwdata(apb_pwdata),
        .prdata_in(uart_prdata), // Input from UART
        .pready_in(uart_pready)  // Input from UART
    );

    // --- UART PERIPHERAL ---
    apb_uart u_uart (
        .clk(clk),
        .rst_n(rst_n),
        .psel(apb_psel),
        .penable(apb_penable),
        .paddr(apb_paddr),
        .pwrite(apb_pwrite),
        .pwdata(apb_pwdata),
        .prdata(uart_prdata),
        .pready(uart_pready),
        .tx(tx_serial)
    );
endmodule