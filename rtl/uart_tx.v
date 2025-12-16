module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start, // Trigger transmission
    input  wire [7:0] data,  // Byte to send
    output reg        tx,    // Serial Output
    output reg        busy   // "I am working" signal
);

    // Timing Constants (Adjust for your clock speed)
    // Example: 10MHz Clock, 115200 Baud -> 87 Clocks/Bit
    // For Simulation, we use a small number to make it fast.
    localparam CLKS_PER_BIT = 100;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_idx;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1; // Idle High
            busy <= 0;
            clk_count <= 0;
            bit_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    busy <= 0;
                    if (start) begin
                        state <= START;
                        data_reg <= data;
                        busy <= 1;
                        clk_count <= 0;
                    end
                end

                START: begin // Send Start Bit (0)
                    tx <= 0;
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                        bit_idx <= 0;
                    end
                end

                DATA: begin // Send 8 Bits
                    tx <= data_reg[bit_idx];
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_idx < 7)
                            bit_idx <= bit_idx + 1;
                        else
                            state <= STOP;
                    end
                end

                STOP: begin // Send Stop Bit (1)
                    tx <= 1;
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                        busy <= 0;
                    end
                end
            endcase
        end
    end
endmodule