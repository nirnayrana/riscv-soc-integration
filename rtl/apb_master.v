module apb_master (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,      // Trigger transaction
    input  wire [31:0] addr,       // Address from CPU
    input  wire [31:0] wdata,      // Data to write
    input  wire        write,      // Write Enable (1=Write, 0=Read)
    output reg         ready,      // Transaction Done
    output reg  [31:0] prdata,     // Data back to CPU
    
    // APB Interface
    output reg         psel,
    output reg         penable,
    output reg  [31:0] paddr,
    output reg         pwrite,
    output reg  [31:0] pwdata,
    input  wire [31:0] prdata_in,  // From Slave
    input  wire        pready_in   // From Slave
);

    // APB States
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (start) next_state = SETUP;
            SETUP:  next_state = ACCESS;
            ACCESS: if (pready_in) next_state = IDLE;
        endcase
    end

    // Output Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psel <= 0; penable <= 0; paddr <= 0; pwrite <= 0; pwdata <= 0; ready <= 0;
        end else begin
            case (next_state)
                IDLE: begin
                    psel <= 0; penable <= 0; ready <= 0;
                end
                SETUP: begin
                    paddr <= addr; pwrite <= write; pwdata <= wdata;
                    psel <= 1; penable <= 0;
                end
                ACCESS: begin
                    penable <= 1;
                    if (pready_in) begin
                        ready <= 1;
                        if (!write) prdata <= prdata_in;
                    end
                end
            endcase
        end
    end
endmodule