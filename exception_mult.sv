`timescale 1ns / 1ps

module exception_mult (
    input logic [31:0] a, b, z_calc,
    input logic [2:0] round,
    output logic [31:0] z,
    output logic ovf, unf, inexact,
    output logic [7:0] status
);
    
    logic [7:0] exp_a, exp_b;
    logic zero_a, zero_b, inf_a, inf_b, nan_a, nan_b;
    
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];
    assign zero_a = (exp_a == 8'b0);
    assign zero_b = (exp_b == 8'b0);
    assign inf_a = (exp_a == 8'hFF && a[22:0] == 0);
    assign inf_b = (exp_b == 8'hFF && b[22:0] == 0);
    assign nan_a = (exp_a == 8'hFF && a[22:0] != 0);
    assign nan_b = (exp_b == 8'hFF && b[22:0] != 0);
    
    always @(*) begin
        status = 8'b0;
        if (nan_a || nan_b) begin
            z = {1'b0, 8'hFF, 23'h400000}; // Quiet NaN
            status[2] = 1; // NaN flag
        end else if (inf_a || inf_b) begin
            z = {a[31] ^ b[31], 8'hFF, 23'h0}; // Infinity
            status[1] = 1; // Inf flag
        end else if (zero_a || zero_b) begin
            z = {a[31] ^ b[31], 8'b0, 23'b0}; // Zero
            status[0] = 1; // Zero flag
        end else begin
            z = z_calc;
            ovf = (z_calc[30:23] > 8'hFE);
            unf = (z_calc[30:23] < 8'h01);
            status[3] = ovf;
            status[4] = unf;
            status[5] = inexact;
        end
    end

endmodule