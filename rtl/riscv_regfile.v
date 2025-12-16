module riscv_regfile (
    input wire clk,
    input wire we3,           // Write Enable
    input wire [4:0] ra1,     // Read Address 1
    input wire [4:0] ra2,     // Read Address 2
    input wire [4:0] wa3,     // Write Address 3
    input wire [31:0] wd3,    // Write Data 3
    output wire [31:0] rd1,   // Read Data 1
    output wire [31:0] rd2    // Read Data 2
);
    reg [31:0] rf[31:0];
    integer i;

    initial begin
        for (i=0; i<32; i=i+1) rf[i] = 0;
    end

    always @(posedge clk) begin
        if (we3 && wa3 != 0) rf[wa3] <= wd3;
    end

    assign rd1 = (ra1 == 0) ? 0 : rf[ra1];
    assign rd2 = (ra2 == 0) ? 0 : rf[ra2];
endmodule