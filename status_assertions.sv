module test_status_bits (
    input logic inf_f,
    input logic zero_f,
    input logic nan_f,
    input logic tiny_f,
    input logic huge_f,
  input bit enable_assertions,
  input bit verbose_pass
);

  	
    // Assert that no two conflicting status flags are high at the same time
    always_comb begin
        if (enable_assertions) begin
            assert_zero_inf:
            assert (!(zero_f && inf_f))
                else $error("FAIL: zero_f and inf_f both high at time %0t", $time);
            if(verbose_pass && !(zero_f && inf_f)) $display("PASS: zero_f and inf_f not both high at time %0t", $time);
    
            assert_zero_nan:
            assert (!(zero_f && nan_f))
                else $error("FAIL: zero_f and nan_f both high at time %0t", $time);
            if(verbose_pass && !(zero_f && nan_f)) $display("PASS: zero_f and nan_f not both high at time %0t", $time);

            assert_zero_huge:
            assert (!(zero_f && huge_f))
                else $error("FAIL: zero_f and huge_f both high at time %0t", $time);
            if(verbose_pass && !(zero_f && huge_f)) $display("PASS: zero_f and huge_f not both high at time %0t", $time);

            assert_inf_nan:
            assert (!(inf_f && nan_f))
                else $error("FAIL: inf_f and nan_f both high at time %0t", $time);
            if(verbose_pass && !(inf_f && nan_f)) $display("PASS: inf_f and nan_f not both high at time %0t", $time);

            assert_inf_tiny:
            assert (!(inf_f && tiny_f))
                else $error("FAIL: inf_f and tiny_f both high at time %0t", $time);
            if(verbose_pass && !(inf_f && tiny_f)) $display("PASS: inf_f and tiny_f not both high at time %0t", $time);

            assert_nan_tiny:
            assert (!(nan_f && tiny_f))
                else $error("FAIL: nan_f and tiny_f both high at time %0t", $time);
            if(verbose_pass && !(nan_f && tiny_f)) $display("PASS: nan_f and tiny_f not both high at time %0t", $time);

            assert_nan_huge:
            assert (!(nan_f && huge_f))
                else $error("FAIL: nan_f and huge_f both high at time %0t", $time);
            if(verbose_pass && !(nan_f && huge_f)) $display("PASS: nan_f and huge_f not both high at time %0t", $time);

            assert_tiny_huge:
            assert (!(tiny_f && huge_f))
                else $error("FAIL: tiny_f and huge_f both high at time %0t", $time);
            if(verbose_pass && !(tiny_f && huge_f)) $display("PASS: tiny_f and huge_f not both high at time %0t", $time);
        end
    end
endmodule



module test_status_z_combinations (
    input logic clk,
    input logic [31:0] a, b, z,
    input logic zero_f, inf_f, nan_f, huge_f, tiny_f,
  	input bit enable_assertions,
    input bit verbose_pass
);

    // Macros for exponent and mantissa bits
    function logic all_zeros(input [7:0] bits); 
        return bits == 8'b00000000;
    endfunction 

    function logic all_ones(input [7:0] bits);
        return bits == 8'b11111111;
    endfunction

    function logic is_maxNorm(input [31:0] val);
        return val[30:23] == 8'b11111110 && val[22:0] == 23'h7FFFFF;
    endfunction

    function logic is_minNorm(input [31:0] val);
        return val[30:23] == 8'b00000001 && val[22:0] == 0;
    endfunction
  
  
  	// Logic Start

    // (1) If zero_f = 1, exponent of z must be all 0
    property zero_means_exp_zero;
      	@(posedge clk) disable iff (!enable_assertions) 
      	zero_f |-> all_zeros(z[30:23]);
    endproperty
    
  	assert property(zero_means_exp_zero) 
    	else $error("FAIL: zero_f asserted but z.exponent != 0 at %0t", $time);
      
    // If verbose_pass == 1, print pass statement
    always_ff @(posedge clk) begin
        if (enable_assertions && verbose_pass) begin
            if (zero_f && all_zeros(z[30:23]))
                $display("PASS: zero_f implies z.exponent == 0 at %0t", $time);
        end
    end
	
      
    // (2) If inf_f = 1, exponent of z must be all 1
    property inf_means_exp_all_ones;
        @(posedge clk) disable iff (!enable_assertions)
      	inf_f |-> all_ones(z[30:23]);
    endproperty
      
	assert property(inf_means_exp_all_ones)
        else $error("FAIL: inf_f asserted but z.exponent != 255 at %0t", $time);
    
    // If verbose_pass == 1, print pass statement
    always_ff @(posedge clk) begin
        if (enable_assertions && verbose_pass) begin
            if (inf_f && all_ones(z[30:23]))
                $display("PASS: inf_f implies z.exponent == 255 at %0t", $time);
        end
    end
      

    // (3) If nan_f = 1, 3 cycles earlier:
    //     a and b must have exponents [30:23] = 0 and 255 (in any order)
    logic [31:0] a_pipe[0:2], b_pipe[0:2];
    always_ff @(posedge clk) begin
        a_pipe[2] <= a_pipe[1]; a_pipe[1] <= a_pipe[0]; a_pipe[0] <= a;
        b_pipe[2] <= b_pipe[1]; b_pipe[1] <= b_pipe[0]; b_pipe[0] <= b;
    end
  
    property nan_input_combo;
      	@(posedge clk) disable iff (!enable_assertions)
        nan_f |-> (
            (all_zeros(a_pipe[2][30:23]) && all_ones(b_pipe[2][30:23])) ||
            (all_zeros(b_pipe[2][30:23]) && all_ones(a_pipe[2][30:23]))
        );
    endproperty
      
	assert property(nan_input_combo)
        else $error("FAIL: nan_f asserted but a/b did not have exp=0 and 255 three cycles earlier at %0t", $time);
    
    // If verbose_pass == 1, print pass statement
    always_ff @(posedge clk) begin
        if (enable_assertions && verbose_pass) begin
          if (nan_f && ((all_zeros(a_pipe[2][30:23]) && all_ones(b_pipe[2][30:23])) || (all_zeros(b_pipe[2][30:23]) && all_ones(a_pipe[2][30:23]))))
                $display("PASS: nan_f implies a/b had exp=0 and 255 (3 cycles ago) at %0t", $time);
        end
    end
      
      
    // (4) huge_f => z = inf OR maxNorm
    property huge_z_check;
      	@(posedge clk) disable iff (!enable_assertions)
        huge_f |-> (all_ones(z[30:23]) || is_maxNorm(z));
    endproperty

    assert property(huge_z_check)
      else $error("FAIL: huge_f asserted but z is not inf or maxNorm at %0t", $time);
    
    // If verbose_pass == 1, print pass statement
    always_ff @(posedge clk) begin
        if (enable_assertions && verbose_pass) begin
            if (huge_f && (all_ones(z[30:23]) || is_maxNorm(z)))
              $display("PASS: huge_f implies z is inf or maxNorm at %0t", $time);
        end
    end
      
      
    // (5) tiny_f => z = 0 OR minNorm
    property tiny_z_check;
      @(posedge clk) disable iff (!enable_assertions)
        tiny_f |-> (all_zeros(z[30:23]) || is_minNorm(z));
    endproperty
       
	assert property(tiny_z_check)
      	else $error("FAIL: tiny_f asserted but z is not 0 or minNorm at %0t", $time);
    
    // If verbose_pass == 1, print pass statement
    always_ff @(posedge clk) begin
        if (enable_assertions && verbose_pass) begin
            if (tiny_f && (all_zeros(z[30:23]) || is_minNorm(z)))
              $display("PASS: tiny_f implies z is 0 or minNorm at %0t", $time);
        end
    end
      
endmodule
      