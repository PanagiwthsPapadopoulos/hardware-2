`timescale 1ns / 1ps
`include "round_defs.sv"

module fp_mult (
    input logic [31:0] a, b,                // IEEE 754 single precision inputs
    input logic [2:0] rnd,                  // Rounding mode
    output logic [31:0] z,                  // Final result (with exceptions handled)
    output logic [7:0] status,              // Status flags from exception_mult
    input logic clk,                        // Clock input (unused internally but required by wrapper)
    input logic rst                         // Reset input (unused internally but required by wrapper)
);

    // =========================================================================
    // (1) SIGN CALCULATION
    // =========================================================================
    logic sign_bit;
    assign sign_bit = a[31] ^ b[31];        // XOR the sign bits

    // =========================================================================
    // (2) EXPONENT ADDITION
    // =========================================================================
    logic [7:0] exp_a, exp_b;
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];

    logic [9:0] exponent_sum;
    assign exponent_sum = exp_a + exp_b;    // raw exponent sum

    // =========================================================================
    // (3) SUBTRACT BIAS
    // =========================================================================
    logic [9:0] exponent_biased;
    assign exponent_biased = exponent_sum - 10'd127;

    // =========================================================================
    // (4) MANTISSA MULTIPLICATION (WITH IMPLICIT LEADING ONES)
    // =========================================================================
    logic [23:0] mantissa_a, mantissa_b;
    logic [47:0] mantissa_mult;
    logic denorm_a, denorm_b;
    assign denorm_a = (exp_a == 8'd0);
    assign denorm_b = (exp_b == 8'd0);

    assign mantissa_a = denorm_a ? 24'd0 : {1'b1, a[22:0]};
    assign mantissa_b = denorm_b ? 24'd0 : {1'b1, b[22:0]};

always @(posedge clk) begin
    if (a == 32'h3f800000 && b == 32'h40000000) begin
        $display("[fp_mult DEBUG] a = 0x%08X, b = 0x%08X", a, b);
        $display("[fp_mult DEBUG] a[30:23] = 0x%02X, a[22:0] = 0x%06X", a[30:23], a[22:0]);
        $display("[fp_mult DEBUG] b[30:23] = 0x%02X, b[22:0] = 0x%06X", b[30:23], b[22:0]);
        $display("[fp_mult DEBUG] mantissa_a = 0x%06X", mantissa_a);
        $display("[fp_mult DEBUG] mantissa_b = 0x%06X", mantissa_b);
        $display("[fp_mult DEBUG] mantissa_mult = 0x%012X", mantissa_mult);
    end
end

  
    assign mantissa_mult = mantissa_a * mantissa_b;

    
  //=========================================================================
    // (5) NORMALIZATION MODULE
    // =========================================================================
  logic [22:0] norm_mantissa;
    logic [9:0] norm_exponent;
    logic guard, sticky;

    normalize_mult normalize_unit (
        .P(mantissa_mult),
        .exp_in(exponent_biased),
        .mant_out(norm_mantissa),
        .exp_out(norm_exponent),
        .guard(guard),
        .sticky(sticky)
    );

    // =========================================================================
    // (6) ROUNDING MODULE
    // =========================================================================
    logic [24:0] rounded_mantissa;
    logic inexact;

    round_mult round_unit (
        .mant_in(norm_mantissa),    // include leading one
        .guard(guard),
        .sticky(sticky),
        .sign(sign_bit),
        .round(rnd),
        .mant_out(rounded_mantissa),
        .inexact(inexact)
    );

    // Post-rounding normalization (adjust exponent if mantissa overflows)
    logic [9:0] rounded_exp;
    assign rounded_exp = (rounded_mantissa[24]) ?
      					 (norm_exponent + 1) :
                         norm_exponent;

  
  always @(posedge clk) begin
  $display("[fp_mult FINAL DEBUG] rounded_mantissa = 0x%06X", rounded_mantissa);
  $display("[fp_mult FINAL DEBUG] rounded_mantissa[24] = %b", rounded_mantissa[24]);
  $display("[fp_mult FINAL DEBUG] norm_exponent = %d", norm_exponent);
  $display("[fp_mult FINAL DEBUG] rounded_exp = %d", rounded_exp);
end
  
  
    logic [22:0] mantissa_out;
  assign mantissa_out = rounded_mantissa[22:0];  // drop the leading one
  
  logic [7:0] final_exp;
assign final_exp = rounded_exp[7:0];

    // Construct z_calc: sign | exponent | mantissa
    logic [31:0] z_calc;
    assign z_calc = {sign_bit, final_exp, mantissa_out};


    // Overflow and Underflow Detection (based on post-rounding exponent)
    logic ovf, unf;
  assign ovf = (rounded_exp > 10'd254);   // Exponent overflow
  assign unf = (rounded_exp < 10'd1);     // Exponent underflow

  always @(posedge clk) begin
    $display("[fp_mult] rounded_mantissa = 0x%06X, bit24 = %b", rounded_mantissa, rounded_mantissa[24]);
$display("[fp_mult] norm_exponent = %0d, rounded_exp = %0d", norm_exponent, rounded_exp);

  end
  
    // =========================================================================
    // (7) EXCEPTION HANDLING MODULE
    // =========================================================================
    logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f;

    exception_mult exception_unit (
        .a(a),
        .b(b),
        .z_calc(z_calc),
        .round(rnd),
        .ovf(ovf),
        .unf(unf),
        .inexact(inexact),
        .z(z),
        .zero_f(zero_f),
        .inf_f(inf_f),
        .nan_f(nan_f),
        .tiny_f(tiny_f),
        .huge_f(huge_f),
        .inexact_f(inexact_f)
    );

    // =========================================================================
    // Compose the 8-bit status signal from exception flags (bits 6-7 unused)
    // =========================================================================
    assign status = {
        2'b00,       // Reserved or unused
        inexact_f,   // Bit 5
        huge_f,      // Bit 4
        tiny_f,      // Bit 3
        nan_f,       // Bit 2
        inf_f,       // Bit 1
        zero_f       // Bit 0
    };
initial begin
    #1;
    $display("[fp_mult] a = 0x%08X, b = 0x%08X", a, b);
    $display("[fp_mult] mantissa_a = 0x%06X, mantissa_b = 0x%06X", mantissa_a, mantissa_b);
    $display("[fp_mult] mantissa_mult = 0x%012X", mantissa_mult);
    $display("[fp_mult] norm_mantissa = 0x%06X, norm_exponent = %0d", norm_mantissa, norm_exponent);
    $display("[fp_mult] rounded_mantissa = 0x%06X, rounded_exp = %0d", rounded_mantissa, rounded_exp);
    $display("[fp_mult] z_calc = 0x%08X", z_calc);
end

endmodule

