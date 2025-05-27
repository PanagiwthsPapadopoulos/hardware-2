`timescale 1ns / 1ps

`include "round_defs.sv"



module round_mult (
    input logic [23:0] mant_in,
    input logic guard, sticky, sign,
    input logic [2:0] round,
    output logic [24:0] mant_out,
    output logic inexact
);

always @(*) begin
	// Find if the multiplication of the two mantissas leads to an exact number
    inexact = guard | sticky;
  
    mant_out = mant_in;
    case (round)
        IEEE_NEAR: mant_out = (guard && (sticky || mant_in[0])) ? mant_in + 1 : mant_in;
        IEEE_ZERO: mant_out = mant_in; 
      	IEEE_PINF: mant_out = (!sign && inexact) ? mant_in + 1 : mant_in;
      	IEEE_NINF: mant_out = (sign && inexact) ? mant_in + 1 : mant_in;
        NEAR_UP: mant_out = guard ? mant_in + 1 : mant_in;
      	AWAY_ZERO: mant_out = (inexact) ? mant_in + 1 : mant_in;
        default: mant_out = (guard && (sticky || mant_in[0])) ? mant_in + 1 : mant_in; 
    endcase
    
  // If rounding caused mantissa to overflow (25th bit), shift right
    if (mant_out[24]) begin
        // Shift mantissa bitwise to the right by 1
        mant_out = mant_out >> 1;
      
      	// Increase exponent value by 1
      	// ... this is done in fp_mult.sv
    end

end

endmodule
