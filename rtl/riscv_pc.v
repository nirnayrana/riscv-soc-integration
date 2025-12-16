module riscv_pc (
    input wire clk,
    input wire rst,
    input wire stall,    
    input wire [31:0] next_pc,
    output reg [31:0] pc
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc <= 0;   
        end else begin
            if (!stall) begin
                pc <= next_pc; 
            end
        end
    end
endmodule