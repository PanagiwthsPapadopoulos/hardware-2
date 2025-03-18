`timescale 1ns / 1ps

module normalize_mult (
    input logic [47:0] P,
    input logic [9:0] exp_in,
    output logic guard, sticky,
    output logic [23:0] mant_out,
    output logic [9:0] exp_out
);
    
always @(*) begin
    exp_out = exp_in;  // Default assignment
    if (P[47]) begin
        // When MSB is 1, shift left
        mant_out = P[46:23]; 
        guard = P[22];
        sticky = |P[21:0]; 
        exp_out = exp_in + 1;
    end else begin
        // When MSB is 0, no shift
        mant_out = P[45:22];
        guard = P[21];
        sticky = |P[20:0];
    end
end

endmodule
