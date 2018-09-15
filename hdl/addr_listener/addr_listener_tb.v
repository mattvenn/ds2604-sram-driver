`timescale 1ns/1ns
`default_nettype none
module test;

    localparam sc_100_k = 13'h1148; // 00
    localparam sc_10_k  = 13'h1149; // 03
    localparam sc_1_k   = 13'h114a; // 00
    localparam sc_100   = 13'h114b; // 02
    localparam sc_10    = 13'h114c; // 09
    localparam sc_1     = 13'h114d; // 00

    reg reset = 1;
    /* Make a reset that pulses once. */
    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,test);

        # 8;
        reset <= 0;
        # 8;

            address <= sc_10_k;
            re <= 0;
            data_write <= 8'h04;
            start <= 1;
            wait(ready == 0);
            start <= 0;
            wait(ready == 1);

            address <= sc_1_k;
            re <= 0;
            data_write <= 8'h08;
            start <= 1;
            wait(ready == 0);
            start <= 0;
            wait(ready == 1);
    
        # 8;

        $finish;

    end

    reg clk = 0;

    always #1 clk = !clk;

    reg re = 0;
    reg start = 0;
    wire ready;
    reg [12:0] address = 0;
    reg [7:0] data_write = 0;
    wire [7:0] sram_data_pins;
    wire [12:0] sram_address;
    wire sram_n_write, sram_n_ce1;

    // addr listener
    top top_inst(.clk(clk), 
        .sram_data_pins(sram_data_pins), 
        .sram_address(sram_address),
        .sram_n_write(sram_n_write),
        .sram_n_ce1(sram_n_ce1));

    // sram driver
    sram_driver #(.WAIT_TIME(3)) sram_driver_0(
        .clk(clk),
        .reset(reset),

        // module interface
        .ready(ready),
        .re(re),
        .start(start),
        .address(address),
        .data_write(data_write),

        // sram control pins
        .sram_address(sram_address),
        .sram_data_write(sram_data_pins),
        .n_ce1(sram_n_ce1),
        .n_we(sram_n_write)
    );


    endmodule
