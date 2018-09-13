`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

`timescale 1ns/1ns
`default_nettype none
`include "../serial/baudgen.vh"
module test;
    task send_data;
    integer i;
    input [39:0] data;
    begin
        for(i = 0; i < 5; i ++) begin
            txdata <= data[39:32];
            data <= data << 8;
            wait(tx_ready == 1);
            tx_strb <= 1;
            wait(tx_ready == 0);
            tx_strb <= 0;
        end
        // last byte
        txdata <= 0;
        wait(tx_ready == 1);
        tx_strb <= 1;
        wait(tx_ready == 0);
        tx_strb <= 0;
    end
    endtask

    localparam BAUD = `B115200;

    // state machine states
    localparam ADDR = 8'h1;
    localparam LOAD = 8'h2;
    localparam WRITE = 8'h3;
    localparam READ = 8'h4;
    localparam READ_REQ = 8'h5;
    localparam COUNT = 8'h6;
    localparam CONST = 8'h7;

    reg reset = 1;
    /* Make a reset that pulses once. */
    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,test);

        # 40;
        reset <= 0;
        # 40;

        send_data({ADDR,32'd1});
        # 1000
        send_data({LOAD,32'd1});
        # 1000
        send_data({WRITE,32'd0});
        # 1000

        send_data({ADDR,32'd1});
        # 1000
        send_data({READ_REQ,32'd0});
        # 1000
        send_data({READ,32'd0});
        # 100000
 
        $finish;

    end

    // about 12mhz with 1ns timescale
    reg clk = 0;

    always #1 clk = !clk;

    wire tx;
    wire tx_ready;
    reg [7:0] txdata = 0;
    reg tx_strb = 0;

    assign top_inst.sram_data_read = 8'b0;
    top top_inst(.clk(clk), .rx(tx) );

    uart_tx #(.BAUD(BAUD)) TX0 ( .clk(clk),
             .rstn(!reset),
             .start(tx_strb),
             .data(txdata),
             .tx(tx),
             .ready(tx_ready)
           );

    endmodule

