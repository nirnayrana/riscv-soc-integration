module apb_master(
    input wire clk,
    input wire rst_n,
    input wire [31:0] cpu_addr,
    input wire [31:0] cpu_wdata,
    input wire cpu_mem_write,
    input wire cpu_mem_read,
    output reg [31:0] cpu_rdata,
    output reg cpu_stall,
    output reg [31:0] paddr,
    output reg [31:0] pwdata,
    output reg pwrite,
    output reg psel,
    output reg penable,
    input wire [31:0] prdata,
    input wire pready
);
    localparam IDLE=2'b00;
    localparam SETUP=2'b01;
    localparam ACCESS=2'b10;
    reg[1:0] state, next_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state<=IDLE;
        else state<=next_state;
    end
    always @(*) begin
        next_state=state;
        psel=0;
        penable=0;
        cpu_stall=0;
        paddr=cpu_addr;
        pwdata=cpu_wdata;
        pwrite=cpu_mem_write;
        case(state)
            IDLE: begin
                if(cpu_mem_write||cpu_mem_read) begin
                    next_state=SETUP;
                    cpu_stall=1;
                end
            end
            SETUP: begin
                psel=1;
                penable=0;
                next_state=ACCESS;
                cpu_stall=1;
            end
            ACCESS: begin
                psel=1;
                penable=1;
                if (pready) begin
                    cpu_stall=0;
                    next_state=IDLE;
                    if(!pwrite) cpu_rdata=prdata;
                end else begin
                    cpu_stall=1;
                    next_state=ACCESS;
                end
            end
        endcase
    end
endmodule