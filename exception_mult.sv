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

    function automatic interp_t num_interp(input logic [31:0] val);
        logic [7:0] exp;
        logic [22:0] mant;
        begin
            exp = val[30:23];
            mant = val[22:0];
            if (exp == 8'b0 && mant == 23'b0)
                num_interp = ZERO;
            else if (exp == 8'hFF && mant == 23'b0)
                num_interp = INF;
            else if (exp == 8'hFF && mant != 23'b0)
                num_interp = NAN;
            else
                num_interp = NORM;
        end
    endfunction

    function automatic logic [30:0] z_num(input interp_t category);
        begin
            case (category)
                ZERO:     z_num = 31'b0;
                INF:      z_num = {8'hFF, 23'b0};
                NAN:      z_num = {8'hFF, 23'b1};
                MIN_NORM: z_num = {8'd1, 23'b0};
                MAX_NORM: z_num = {8'd254, 23'h7FFFFF};
                default:  z_num = 31'bx;
            endcase
        end
    endfunction

    interp_t class_a, class_b;
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

        // Sign bit from a ⊕ b
        // sign_bit = a[31] ^ b[31];

        // Determine types
        class_a = num_interp(a);
        class_b = num_interp(b);

        // NaN takes priority
        if (class_a == NAN || class_b == NAN) begin
            z      = {1'b0, z_num(NAN)};
            nan_f  = 1;
        end
        else if (class_a == INF || class_b == INF) begin
            z     = {sign_bit, z_num(INF)};
            inf_f = 1;
        end
        else if (class_a == ZERO || class_b == ZERO) begin
            z      = {sign_bit, z_num(ZERO)};
            zero_f = 1;
        end
        else begin
            // Normal x Normal cases
            huge_f     = ovf;
            tiny_f     = unf;
            inexact_f  = inexact;

            if (ovf) begin
                if ((round == 3'b000 && !sign_bit) ||  // round to +Inf
                    (round == 3'b001 && sign_bit)  ||  // round to -Inf
                    (round == 3'b100)) begin           // round to nearest
                    z = {sign_bit, z_num(INF)};
                    inf_f = 1;
                end else begin
                    z = {sign_bit, z_num(MAX_NORM)};
                end
            end
            else if (unf) begin
                if ((round == 3'b000 && sign_bit) ||   // round to -0
                    (round == 3'b001 && !sign_bit) ||  // round to +0
                    (round == 3'b100)) begin           // round to nearest
                    z = {sign_bit, z_num(ZERO)};
                    zero_f = 1;
                end else begin
                    z = {sign_bit, z_num(MIN_NORM)};
                end
            end
            else begin
                z = z_calc;
            end
        end
    end

endmodule
