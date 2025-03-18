`timescale 1ns / 1ps

module fp_mult (
    input logic [31:0] a, b,
    input logic [2:0] rnd,
    output logic [31:0] z,
    output logic [7:0] status
);

    logic sign;
    logic [9:0] exp_sum;
    logic [47:0] mant_mult;
    logic [23:0] norm_mant;
    logic [9:0] norm_exp;
    logic guard, sticky;
    logic [24:0] rounded_mant;
    logic [9:0] post_exp;
    logic [31:0] z_calc;
    logic ovf, unf;
    input logic inexact_internal;  // Now only an internal signal

    // Compute sign, exponent sum, and mantissa multiplication
    assign sign = a[31] ^ b[31];
    assign exp_sum = {2'b00, a[30:23]} + {2'b00, b[30:23]} - 10'd127;
    assign mant_mult = {1'b1, a[22:0]} * {1'b1, b[22:0]};

    // Normalization
    normalize_mult norm (
        .P(mant_mult),
        .exp_in(exp_sum),
        .guard(guard),
        .sticky(sticky),
        .mant_out(norm_mant),
        .exp_out(norm_exp)
    );

    // Rounding
    round_mult round (
        .mant_in({1'b1, norm_mant}),
        .guard(guard),
        .sticky(sticky),
        .sign(sign),
        .round(rnd),
        .mant_out(rounded_mant),
        .inexact(inexact_internal)  // Internal signal
    );

    // Exception Handling - Now treats `inexact_internal` as an input
    exception_mult exc (
        .a(a),
        .b(b),
        .z_calc({sign, norm_exp[7:0], rounded_mant[22:0]}),
        .round(rnd),
        .z(z),
        .ovf(ovf),
        .unf(unf),
        .inexact(inexact_internal),  // Pass as input
        .status(status)
    );

endmodule