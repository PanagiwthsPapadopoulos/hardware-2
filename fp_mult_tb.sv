`include "fp_mult.sv"
`include "normalize_mult.sv"
`include "exception_mult.sv"
`include "round_mult.sv"

`timescale 1ns / 1ps

module fp_mult_tb;

    logic [31:0] a, b;
    logic [2:0] rnd;
    logic [31:0] z;
    logic [7:0] status;
    
    fp_mult uut (
        .a(a), .b(b), .rnd(rnd), .z(z), .status(status)
    );
    
    initial begin
        $display("Starting Floating Point Multiplier Testbench");
        rnd = 3'b000;

        // Normal operation tests
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        #10;
        $display("Test 1: 1.0 * 2.0 = %h, Status: %b", z, status);
        
        a = 32'hC0000000; // -2.0
        b = 32'h40000000; // 2.0
        #10;
        $display("Test 2: -2.0 * 2.0 = %h, Status: %b", z, status);
        
        // Corner case tests
        a = 32'h7F800000; // +Infinity
        b = 32'h3F800000; // 1.0
        #10;
        $display("Test 3: Inf * 1.0 = %h, Status: %b", z, status);
        
        a = 32'h7F800000; // +Infinity
        b = 32'h7F800000; // +Infinity
        #10;
        $display("Test 4: Inf * Inf = %h, Status: %b", z, status);
        
        a = 32'h00000000; // Zero
        b = 32'h7F800000; // +Infinity
        #10;
        $display("Test 5: 0 * Inf = %h, Status: %b", z, status);
        
        a = 32'h7FC00000; // NaN
        b = 32'h3F800000; // 1.0
        #10;
        $display("Test 6: NaN * 1.0 = %h, Status: %b", z, status);

        $finish;
    end

endmodule
