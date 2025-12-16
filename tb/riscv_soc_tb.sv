`timescale 1ns/1ns
module riscv_soc_tb;
    reg clk;
    reg rst_n;
    wire tx_serial;
    riscv_soc uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_serial(tx_serial)
    );
    always #5 clk = ~clk;
    initial begin
        $dumpfile("soc_simulation.vcd");
        $dumpvars(0, riscv_soc_tb);
        $readmemh("program.hex", uut.IMEM.RAM);
        // Spy on the Data Path
    $monitor("Time: %3d | PC: %h | Instr: %h | Addr: %h | Write: %b | Is_Periph: %b | State: %b", 
             $time, 
             uut.cpu.pc, 
             uut.cpu.instr, 
             uut.cpu_data_addr,   // The calculated address
             uut.cpu_mem_write,   // Is CPU trying to write?
             uut.is_peripheral,   // Did we detect FFFF0000?
             uut.bridge.state     // Bridge State
    );
        clk = 0; rst_n = 0;
        #20;
        rst_n = 1;
        $display("--- Starting Simulation ---");
        $display("Expected Output: Serial transmission of 'H' (0x48) then 'I' (0x49)");
        #4000; 
        $display("--- Simulation Finished ---");
        $finish;
    end
    reg [7:0] rx_byte;
    integer bit_idx;
    initial begin
        forever begin
            @(negedge tx_serial);
            #150; 
            for (bit_idx=0; bit_idx<8; bit_idx=bit_idx+1) begin
                rx_byte[bit_idx] = tx_serial;
                #100;
            end
            $display("UART RECEIVER: Detected Character '%c' (Hex: %h)", rx_byte, rx_byte);
        end
    end
endmodule