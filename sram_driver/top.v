`default_nettype none

module top (
	input           clk,
    output          LED,
    inout [7:0]     sram_data_pins,
    output [13:0]   sram_address,
    output          n_ce1,
    output          ce2,
    output          n_we,
    output          n_oe
);

    reg reset = 1;

    always @(posedge clk)
        reset <= 0;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) sram_data [7:0] (
        .PACKAGE_PIN(sram_data_pins),
        .OUTPUT_ENABLE(sram_data_pins_oe),
        .D_OUT_0(sram_data_write),
        .D_IN_0(sram_data_read),
    );

    wire ready;
    reg [12:0] address = 0;
    reg [7:0] data_in = 0;
    wire [7:0] data_out;
    reg re = 0;
    reg start = 0;

    // wires for sram chip
    wire sram_data_pins_oe;
    wire [7:0] sram_data_write;
    wire [7:0] sram_data_read;

    // sram driver
    sram_driver sram_driver_0(
        .clk(clk),
        .reset(reset),

        // module interface
        .ready(ready),
        .re(re),
        .start(start),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),

        // sram control pins
        .sram_address(sram_address),
        .sram_data_read(sram_data_read),
        .sram_data_write(sram_data_write),
        .sram_data_pins_oe(sram_data_pins_oe),
        .n_ce1(n_ce1),
        .ce2(ce2),
        .n_we(n_we),
        .n_oe(n_oe)
    );

endmodule

