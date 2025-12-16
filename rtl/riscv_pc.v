module riscv_pc (
    input wire clk,
    input wire rst,
    input wire [31:0] pc_next,  // Matches "pc_next" in top level
    output reg [31:0] pc_current // Matches "pc_current" in top level
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_current <= 32'h00000000;
        else
            pc_current <= pc_next;
    end
endmodule