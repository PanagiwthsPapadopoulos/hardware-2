`timescale 1ns / 1ps

module round_mult (
    input logic [24:0] mant_in,
    input logic guard, sticky, sign,
    input logic [2:0] round,
    output logic [24:0] mant_out,
    output logic inexact
);

always @(*) begin
    inexact = guard | sticky;
    case (round)
        3'b000: mant_out = (guard & sticky) ? mant_in + 1 : mant_in; // IEEE nearest
        3'b001: mant_out = (guard) ? mant_in + 1 : mant_in; // Toward +inf
        3'b010: mant_out = (guard & sign) ? mant_in + 1 : mant_in; // Toward -inf
        3'b011: mant_out = mant_in; // Truncate
        default: mant_out = (guard) ? mant_in + 1 : mant_in; // Default to IEEE nearest
    endcase
    if (mant_out[24]) begin
        mant_out >>= 1;
    end
end

endmodule
