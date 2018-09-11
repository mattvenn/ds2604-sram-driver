`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

`timescale 1ns/1ns
`default_nettype none
module test;

    /* Make a reset that pulses once. */
    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,test);
 
        wait(top_inst.state == 4);
        # 1000
        $finish;

    end

    // about 12mhz with 1ns timescale
    reg clk = 0;

    always #80 clk = !clk;

    top top_inst(.clk(clk));

    endmodule

