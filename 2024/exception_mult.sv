`timescale 1ns / 1ps

module exception_mult (
    input  logic [31:0] a, b, z_calc,
    input  logic [2:0]  round,
    input  logic        ovf, unf, inexact,
    output logic [31:0] z,
    output logic        zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f
);

    typedef enum logic [2:0] {
        ZERO,
        INF,
        NAN,
        NORM,
        MIN_NORM,
        MAX_NORM
    } interp_t;

  	// num_interp - Numeric Interpretation
    function automatic interp_t num_interp(input logic [31:0] val);
        logic [7:0] exp;
        logic [22:0] mant;
        //     [31]       [30:23]           [22:0]
        //    sign  |   exponent (8b)  | mantissa (23b)

        begin
          	// Extract exponent and mantissa from z_calc
            exp = val[30:23];
            mant = val[22:0];
            if (exp == 8'b0)
                num_interp = ZERO;
            else if (exp == 8'hFF)
                num_interp = INF; // Treat both true Infinities and NaNs as INF
            else
                num_interp = NORM;
        end
    endfunction

  	// z_num - enum -> unsigned version of the value
    function automatic logic [30:0] z_num(input interp_t category);
        begin
            case (category)
                ZERO:     z_num = 31'b0;
                INF:      z_num = {8'hFF, 23'b0};
              	NAN:      z_num = {8'd255, 23'b1};
                MIN_NORM: z_num = {8'd1, 23'b0};
                MAX_NORM: z_num = {8'd254, 23'h7FFFFF};
                default:  z_num = {8'd0, 23'b0}; // default to 0 or MIN_NORM
            endcase
        end
    endfunction
  
  
  function string interp_to_str(input interp_t c);
    case (c)
        ZERO:     interp_to_str = "ZERO";
        INF:      interp_to_str = "INF";
        NAN:      interp_to_str = "NAN";
        NORM:     interp_to_str = "NORM";
        MIN_NORM: interp_to_str = "MIN_NORM";
        MAX_NORM: interp_to_str = "MAX_NORM";
        default:  interp_to_str = "???";
    endcase
endfunction

  
    interp_t class_a, class_b;
    // assign sign bit as XOR of Sa and Sb
    logic sign_bit;
    assign sign_bit = a[31] ^ b[31];

    always_comb begin
        // Reset all status flags
        zero_f     = 0;
        inf_f      = 0;
        nan_f      = 0;
        tiny_f     = 0;
        huge_f     = 0;
        inexact_f  = 0;

        // Determine types
        class_a = num_interp(a);
        class_b = num_interp(b);

        // NaN takes priority
        if (class_a == NAN || class_b == NAN) begin
          z      = {sign_bit, z_num(NAN)};
            nan_f  = 1;
        end
        else if ((class_a == INF && class_b == ZERO) || (class_b == INF && class_a == ZERO)) begin
        	// Inf * 0 → Inf
            z = {1'b0, z_num(INF)};
            inf_f = 1;
        end
        else if (class_a == INF || class_b == INF) begin
            // Inf * Inf → Inf
            z     = {sign_bit, z_num(INF)};
            inf_f = 1;
        end
        else if (class_a == ZERO || class_b == ZERO) begin
            // 0 * Any → 0
            z      = {sign_bit, z_num(ZERO)};
            zero_f = 1;
        end
        else begin
            // Normal x Normal cases
            huge_f     = ovf;
            tiny_f     = unf;
            inexact_f  = inexact;
          
            //    IEEE_NEAR   x
            //    IEEE_ZERO   x
            //    IEEE_PINF   x
            //    IEEE_NINF   x
            //    NEAR_UP     x
            //    AWAY_ZERO   x

          	// Check for overflow
            if (ovf) begin
              	case (round)
                    IEEE_NEAR: begin
                        z = {sign_bit, z_num(INF)};
                        inf_f = 1;
                    end

                    IEEE_ZERO: begin
                        z = {sign_bit, z_num(MAX_NORM)};
                    end

                    IEEE_PINF: begin
                        if (sign_bit)
                            z = {1'b1, z_num(MAX_NORM)};
                        else begin
                            z = {1'b0, z_num(INF)};
                            inf_f = 1;
                        end
                    end

                    IEEE_NINF: begin
                        if (sign_bit) begin
                            z = {1'b1, z_num(INF)};
                            inf_f = 1;
                        end else
                            z = {1'b0, z_num(MAX_NORM)};
                    end
                  
                    NEAR_UP: begin
                        z = {sign_bit, z_num(INF)};
                        inf_f = 1;
                    end

                    AWAY_ZERO: begin
                        z = {sign_bit, z_num(INF)};
                        inf_f = 1;
                    end
                endcase
            end
            // Check for underflow
            else if (unf) begin
                case (round)
                    IEEE_NEAR: begin
                        z = {sign_bit, z_num(ZERO)};
                        zero_f = 1;
                    end

                    IEEE_ZERO: begin
                      z = {sign_bit, z_num(ZERO)};
                    end

                    IEEE_PINF: begin
                        if (sign_bit)
                          z = {1'b1, z_num(ZERO)};
                        else begin
                          z = {1'b0, z_num(MIN_NORM)};
                            zero_f = 1;
                        end
                    end

                    IEEE_NINF: begin
                        if (sign_bit) begin
                            z = {1'b1, z_num(MIN_NORM)};  // negative → round further negative
                        end else begin
                            z = {1'b0, z_num(ZERO)};      // positive → round down → towards 0
                            zero_f = 1;
                        end
                    end
                  
                    NEAR_UP: begin
                        z = {sign_bit, z_num(ZERO)};
                        zero_f = 1;
                    end

                    AWAY_ZERO: begin
                      z = {sign_bit, z_num(MIN_NORM)};
                        zero_f = 1;
                    end
                endcase

        	end
		 
      
            else begin
                z = z_calc;
            end
        end
    
    end

endmodule

