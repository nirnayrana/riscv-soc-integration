module riscv_pipe_reg #(parameter N=32) (
    input wire clk,
    input wire rst,
    input wire clear,
    input wire en,
    input wire [N-1:0]d,
    output reg [N-1:0]q
);
    always @(posedge clk or posedge rst) begin
        if (rst) q<=0;
        else if (clear) q<=0;
        else if (en) q<=d;
    end
endmodule