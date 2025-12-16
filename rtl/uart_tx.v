module uart_tx #(
    parameter CLK_FREQ=100000000,
    parameter BAUD_RATE=9600
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx_busy,
    output reg tx_serial
);
    localparam CLKS_PER_BIT=CLK_FREQ/BAUD_RATE;
    localparam IDLE=2'b00;
    localparam START=2'b01;
    localparam DATA=2'b10;
    localparam STOP=2'b11;
    reg [1:0] state, next_state;
    reg [31:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_temp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_serial <= 1; 
            tx_busy <= 0;
            clk_count <= 0;
            bit_index <= 0;
            data_temp <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_serial <= 1;
                    tx_busy   <= 0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        state <= START;
                        tx_busy <= 1;
                        data_temp <= tx_data;
                    end
                end
                START: begin
                    tx_serial <= 0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end
                DATA: begin
                    tx_serial <= data_temp[bit_index];

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                STOP: begin
                    tx_serial <= 1;

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule