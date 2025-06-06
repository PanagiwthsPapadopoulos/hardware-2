`timescale 1ns / 1ps

`include "round_defs.sv"

// TOP TESTBENCH
// └── fp_mult_tb.sv         <-- Testbench that drives the system
//      └── fp_mult_top.sv   <-- Wrapper module for DUT
//           └── fp_mult.sv  <-- Main datapath module (you must implement this!)
//                ├── normalize_mult.sv  <-- Normalization stage
//                ├── round_mult.sv      <-- Rounding stage
//                └── exception_mult.sv  <-- Exception handling stage

// [fp_mult_tb] → [fp_mult_top] → [fp_mult]
//                                 ├─ normalize_mult
//                                 ├─ round_mult
//                                 └─ exception_mult

module fp_mult_tb;

    // === Inputs to DUT ===
    logic [31:0] a, b;
    round_mode_t round;

    // === Outputs from DUT ===
    logic [31:0] z;
    logic [7:0] status;

    // === Clock (not used by DUT, but spec requires timing) ===
    logic clk = 0;
    always #7.5 clk = ~clk;
  
  	logic rst;
    initial begin
        rst = 0;
        #5;
        rst = 1;
    end

    // === Instantiate DUT ===
    fp_mult_top dut (
      .a(a),
      .b(b),
      .rnd(round),
      .clk(clk),
      .rst(rst),
      .z(z),
      .status(status)
	);

    logic [2:0] mode;
    integer i, j;
    reg [31:0] expected;


    // === Corner Cases (12 values) ===
    logic [31:0] corner_cases[12];

    initial begin
        corner_cases[0]  = 32'h7FA00000; // +sNaN
        corner_cases[1]  = 32'hFFA00000; // -sNaN
        corner_cases[2]  = 32'h7FC00000; // +qNaN
        corner_cases[3]  = 32'hFFC00000; // -qNaN
        corner_cases[4]  = 32'h7F800000; // +Inf
        corner_cases[5]  = 32'hFF800000; // -Inf
        corner_cases[6]  = 32'h3F800000; // +1.0 (normal)
        corner_cases[7]  = 32'hBF800000; // -1.0 (normal)
        corner_cases[8]  = 32'h00000001; // +Denormal
        corner_cases[9]  = 32'h80000001; // -Denormal
        corner_cases[10] = 32'h00000000; // +Zero
        corner_cases[11] = 32'h80000000; // -Zero
    end

    reg [127:0] rstr;
  
  	bit run_random = 1;   // Set to 0 to skip random tests
    bit run_corner = 1;   // Set to 0 to skip corner tests
	bit verbose = 0;      // 0 = only mismatches, 1 = show all

    // === Random Tests ===
    initial begin

        if (run_random) begin
            // === RANDOM TESTS ===
            $display("=== RANDOM TESTS ===");
            
            for (int mode = 0; mode < 6; mode++) begin
                round = round_mode_t'(mode);
                for (int i = 0; i < 500; i++) begin
                    a = $urandom();
                    b = $urandom();

                    @(posedge clk); @(posedge clk);@(posedge clk);@(posedge clk);


                    case (round)
                        3'b000: rstr = "IEEE_near";
                        3'b001: rstr = "IEEE_zero";
                        3'b010: rstr = "IEEE_pinf";
                        3'b011: rstr = "IEEE_ninf";
                        3'b100: rstr = "near_up";
                        3'b101: rstr = "away_zero";
                        default: rstr = "IEEE_near";
                    endcase

                expected = multiplication(rstr, a, b);

                    if (z !== expected) begin
                    $display("RANDOM ERROR: MISMATCH round=%s a=0x%08X b=0x%08X z=0x%08X expected=0x%08X",
                                rstr, a, b, z, expected);
                    end else if (verbose) begin
                    $display("RANDOM ERROR: MATCH    round=%s a=0x%08X b=0x%08X z=0x%08X expected=0x%08X",
                                rstr, a, b, z, expected);
                    end
                end
            end

            $display("=== RANDOM TESTS DONE ===");
        end


        if (run_corner) begin
        
            // === CORNER CASE TESTS ===
            $display("=== CORNER CASE TESTS ===");

            for (mode = 0; mode < 6; mode = mode + 1) begin
                round = round_mode_t'(mode);

                case (round)
                    3'b000: rstr = "IEEE_near";
                    3'b001: rstr = "IEEE_zero";
                    3'b010: rstr = "IEEE_pinf";
                    3'b011: rstr = "IEEE_ninf";
                    3'b100: rstr = "near_up";
                    3'b101: rstr = "away_zero";
                    default: rstr = "IEEE_near";
                endcase

                for (i = 0; i < 12; i = i + 1) begin
                    for (j = 0; j < 12; j = j + 1) begin
                        a = corner_cases[i];
                        b = corner_cases[j];

                            @(posedge clk); @(posedge clk);@(posedge clk);@(posedge clk);



                    expected = multiplication(rstr, a, b);

                        if (z !== expected) begin
                        $display("CORNER ERROR: MISMATCH round=%s a_case=%0d b_case=%0d z=0x%08X expected=0x%08X",
                                    rstr, i, j, z, expected);
                        end else if (verbose) begin
                        $display("RANDOM ERROR: MATCH    round=%s a_case=0x%08X b_case=0x%08X z=0x%08X expected=0x%08X",
                                    rstr, i, j, z, expected);
                        end
                    end
                end
            end
        $display("=== CORNER CASES DONE ===");
        end
        
        
        // Manual Testing
                                
        /*
        a= 32'h9d1fa8ae; // -2.113068e-21
        b = 32'h87b705fc; // -2.7538297e-34
        round = IEEE_NEAR;
        rstr = "IEEE_near";

        @(posedge clk); @(posedge clk);@(posedge clk);@(posedge clk);
        expected = multiplication(rstr, a, b);

        $display("MANUAL TEST: a=0x%08X b=0x%08X z=0x%08X expected=0x%08X", a, b, z, expected);
        $display("MANUAL TEST: a = %f, b = %f, z = %f, expected = %f",
            $bitstoshortreal(a),
            $bitstoshortreal(b),
            $bitstoshortreal(z),
            $bitstoshortreal(expected));
        */
        
        
        
        $finish;
    end

endmodule
