`timescale 1ns / 1ps

module normalize_mult (
    input logic [47:0] P,
    input logic [9:0] exp_in,
    output logic guard, sticky,
    output logic [22:0] mant_out,
    output logic signed [9:0] exp_out
);
    
always @(*) begin
    mant_out = 23'b0;
    guard = 1'b0;
    sticky = 1'b0;
    exp_out = exp_in;  // Default assignment
  
    if (P[47]) begin
        // Mantissa Normalizer
        mant_out = P[46:24]; 

        // Guard bit
        guard = P[23];

        // Sticky bit
      	sticky = |P[22:0]; 

        // Exponent update
        exp_out = exp_in + 1;
      
    end else begin
        // Mantissa Normalizer
        mant_out = P[45:23]; 

        // Guard bit
      	guard = P[22];
      
      	// Sticky bit
      	sticky = |P[21:0];

        // Exponent update
        exp_out = exp_in;
      
    end
  
end

endmodule
