module apb_uart (
    input wire clk,
    input wire rst_n,
    input wire [31:0] paddr,
    input wire [31:0] pwdata,
    input wire        psel,
    input wire        penable,
    input wire        pwrite,
    output reg        pready,
    output reg [31:0] prdata,
    output wire       tx_serial
);
    wire tx_busy;
    reg  tx_start;
    reg  [7:0] tx_data;
    uart_tx #(
        .CLK_FREQ(100), 
        .BAUD_RATE(10)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx_serial(tx_serial)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pready   <= 0;
            tx_start <= 0;
            tx_data  <= 0;
        end else begin
            pready   <= 0;
            tx_start <= 0;
            if (psel && penable) begin
                if (!tx_busy) begin
                    pready <= 1; 
                    
                    if (pwrite) begin
                        tx_data  <= pwdata[7:0]; 
                        tx_start <= 1; 
                    end
                end 
            end
        end
    end
endmodule