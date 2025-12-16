`timescale 1ns/1ns

module riscv_soc_tb;

    reg clk;
    reg rst_n;
    wire tx_serial;

    // Instantiate SoC
    riscv_soc_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_serial(tx_serial)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // UART Receiver Logic (To decode the output)
    reg [7:0] rx_data;
    integer bit_idx;
    integer rx_time_start;

    initial begin
        // Initialize Memory (Load Program)
        // Note: We reference the IMEM inside the Pipeline CPU
        $readmemh("tb/program.hex", uut.uut_cpu.IMEM.mem);

        clk = 0;
        rst_n = 0;
        #20 rst_n = 1;

        $display("--- Starting Pipelined Simulation ---");
        
        // Spy on Pipeline Signals
        $monitor("Time: %4d | PC: %h | Instr: %h | Stall: %b | UART_TX: %b", 
                 $time, 
                 uut.uut_cpu.PC_F,         // Fetch Stage PC
                 uut.uut_cpu.Instr_F,      // Fetch Stage Instruction
                 uut.uart_stall,           // Stall Signal
                 tx_serial);
        
        #50000;
        $display("--- Simulation Timeout ---");
        $finish;
    end

    // UART Decoding Block (Same as before)
    always @(negedge tx_serial) begin
        rx_time_start = $time;
        // Wait 1.5 bit periods (bit period = 1000ns for our simplified UART)
        // Adjust this delay based on your UART baud rate logic.
        // Assuming your uart_tx has CLKS_PER_BIT = 100 (100 * 10ns = 1000ns)
        #1500; 
        
        for (bit_idx=0; bit_idx<8; bit_idx=bit_idx+1) begin
            rx_data[bit_idx] = tx_serial;
            #1000; // Wait 1 bit period
        end
        
        $display("UART RECEIVER: Detected Character '%c' (Hex: %h)", rx_data, rx_data);
    end

endmodule