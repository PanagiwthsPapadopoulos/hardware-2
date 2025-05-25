`timescale 1ns / 1ps

`include "round_defs.sv"



module round_mult (
    input logic [24:0] mant_in,
    input logic guard, sticky, sign,
    input logic [2:0] round,
    output logic [24:0] mant_out,
    output logic inexact
);

always @(*) begin
 

    inexact = guard | sticky;
    mant_out = mant_in;
    case (round)
        IEEE_NEAR: mant_out = (guard && (sticky || mant_in[0])) ? mant_in + 1 : mant_in;
        IEEE_ZERO: mant_out = mant_in; 
        IEEE_PINF: mant_out = (!sign && (guard || sticky)) ? mant_in + 1 : mant_in;
		IEEE_NINF: mant_out = (sign && (guard || sticky)) ? mant_in + 1 : mant_in;
        NEAR_UP: mant_out = guard ? mant_in + 1 : mant_in;
        AWAY_ZERO: mant_out = (guard | sticky) ? mant_in + 1 : mant_in;
        default: mant_out = (guard && (sticky || mant_in[0])) ? mant_in + 1 : mant_in; 
    endcase
  // If rounding caused mantissa to overflow (25th bit), shift right
// The exponent will be incremented later in fp_mult
  
$display("[round] mant_in = 0x%06X, round = %0d, sign = %b", mant_in, round, sign);
$display("[round] guard = %b, sticky = %b → inexact = %b", guard, sticky, inexact);
$display("[round] mant_out (before shift) = 0x%06X", mant_out);

  
    if (mant_out[24]) begin
        mant_out = mant_out >> 1;
    end
  
  $display("[round] mant_out (after shift if any) = 0x%06X", mant_out);

end

endmodule
