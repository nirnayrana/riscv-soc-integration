module apb_uart (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        psel,
    input  wire        penable,
    input  wire [31:0] paddr,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,  // CHANGED: reg -> wire
    output wire        pready,
    output wire        tx
);

    wire tx_busy;
    reg  start_tx;
    reg  [7:0] tx_data;

    // Address Decoding (Write to 0xFFFF0000)
    wire is_uart_addr = (paddr[31:16] == 16'hFFFF);
    
    // UART Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_tx <= 0;
            tx_data <= 0;
        end else begin
            start_tx <= 0; 
            if (psel && penable && pwrite && is_uart_addr && !tx_busy) begin
                start_tx <= 1;
                tx_data <= pwdata[7:0];
            end
        end
    end

    // PREADY Logic
    assign pready = !(psel && is_uart_addr && tx_busy);
    
    // Read Logic (Fixed Warning)
    assign prdata = 32'b0;  // CHANGED: Always block -> assign

    // Instantiate UART Module
    uart_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_tx),
        .data(tx_data),
        .tx(tx),
        .busy(tx_busy)
    );
endmodule