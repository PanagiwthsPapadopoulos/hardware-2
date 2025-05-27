`timescale 1ns / 1ps

`include "round_defs.sv"

module fp_mult_tb;

    logic [31:0] a, b;
    round_mode_t round;
    logic [31:0] z;
    logic [7:0] status;

    logic clk = 0;
    always #5 clk = ~clk; // 10ns clock
    bit enable_assertions = 0;

    logic rst;
    initial begin
        rst = 0;
        #5;
        rst = 1;
    end

    fp_mult_top dut (
        .a(a),
        .b(b),
        .rnd(round),
        .clk(clk),
        .rst(rst),
        .z(z),
        .status(status)
    );
  
    // Bind the test_status_bits assertion module
    bind fp_mult_top test_status_bits checker_bits (
      .zero_f(fp_mult_tb.dut.status[0]),
      .inf_f(fp_mult_tb.dut.status[1]),
      .nan_f(fp_mult_tb.dut.status[2]),
      .tiny_f(fp_mult_tb.dut.status[3]),
      .huge_f(fp_mult_tb.dut.status[4]),
      .enable_assertions(fp_mult_tb.enable_assertions),
      .verbose_pass(fp_mult_tb.verbose_pass)
  	);
  
  	// Bind the test_status_z_combinations module
  	bind fp_mult_top test_status_z_combinations checker_z (
      .clk(fp_mult_tb.clk),
      .a(fp_mult_tb.a),
      .b(fp_mult_tb.b),
      .z(fp_mult_tb.z),
      .zero_f(fp_mult_tb.dut.status[0]),
      .inf_f(fp_mult_tb.dut.status[1]),
      .nan_f(fp_mult_tb.dut.status[2]),
      .tiny_f(fp_mult_tb.dut.status[3]),
      .huge_f(fp_mult_tb.dut.status[4]),
      .enable_assertions(fp_mult_tb.enable_assertions),
      .verbose_pass(fp_mult_tb.verbose_pass)
	);

    logic [2:0] mode;
    integer i, j;
    reg [31:0] expected;
    logic [31:0] expected_pipe[2:0];
    logic [127:0] rstr, rstr_pipe[2:0];

    logic [31:0] corner_cases[12];
    initial begin
        corner_cases[0]  = 32'h7FA00000;
        corner_cases[1]  = 32'hFFA00000;
        corner_cases[2]  = 32'h7FC00000;
        corner_cases[3]  = 32'hFFC00000;
        corner_cases[4]  = 32'h7F800000;
        corner_cases[5]  = 32'hFF800000;
        corner_cases[6]  = 32'h3F800000;
        corner_cases[7]  = 32'hBF800000;
        corner_cases[8]  = 32'h00000001;
        corner_cases[9]  = 32'h80000001;
        corner_cases[10] = 32'h00000000;
        corner_cases[11] = 32'h80000000;
    end
  
    // Simulation Variables
    bit run_random = 1;          // Execute random tests
    bit run_corner = 1;          // Execute corner tests
    bit verbose = 0;             // Print matches for the tests - mismatches are always displayed
    bit verbose_pass = 0;        // Print assertion passes for the tests - erros are always displayed
  

    initial begin
      $dumpfile("dump.vcd");                         // VCD output file
      $dumpvars;                                     // testbench
    
        if (run_random) begin
            $display("=== RANDOM TESTS ===");
          			// === Pipeline priming ===
                // Wait 3 cycles before applying the first test
            @(posedge clk); @(posedge clk); @(posedge clk);
            for (int mode = 0; mode < 6; mode++) begin
                round = round_mode_t'(mode);
                for (int i = 0; i < 500; i++) begin
                  
                    a = $urandom();
                    b = $urandom();
                  
                  // Enable assertions only after the first set of numbers has reached stage 3 of the pipeline
                  if(!enable_assertions) begin
                    @(posedge clk);@(posedge clk);@(posedge clk);
                    enable_assertions = 1;
                  end

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
                    @(posedge clk); @(posedge clk); @(posedge clk);

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

                for (i = 0; i < 12; i++) begin
                    for (j = 0; j < 12; j++) begin
                        a = corner_cases[i];
                        b = corner_cases[j];

                        expected = multiplication(rstr, a, b);
                        @(posedge clk); @(posedge clk); @(posedge clk);

                        if (z !== expected) begin
                            $display("CORNER ERROR: MISMATCH round=%s a_case=%0d b_case=%0d z=0x%08X expected=0x%08X",
                                     rstr, i, j, z, expected);
                        end else if (verbose) begin
                            $display("CORNER ERROR: MATCH    round=%s a_case=0x%08X b_case=0x%08X z=0x%08X expected=0x%08X",
                                     rstr, i, j, z, expected);
                        end
                    end
                end
            end
            $display("=== CORNER CASES DONE ===");
        end

        // === MANUAL TEST CASE ===
        a = 32'h9d1fa8ae; // -2.113068e-21
        b = 32'h87b705fc; // -2.7538297e-34
        round = IEEE_NEAR;
        rstr = "IEEE_near";
        expected = multiplication(rstr, a, b);
        @(posedge clk); @(posedge clk); @(posedge clk);
        $display("MANUAL TEST: a=0x%08X b=0x%08X z=0x%08X expected=0x%08X", a, b, z, expected);
        $display("MANUAL TEST: a = %f, b = %f, z = %f, expected = %f", $bitstoshortreal(a), $bitstoshortreal(b), $bitstoshortreal(z), $bitstoshortreal(expected));

        $finish;
    end
endmodule
