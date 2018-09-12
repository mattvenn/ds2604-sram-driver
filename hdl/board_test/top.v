`default_nettype none
`define TEST_OUTPUT
module top (
	input           clk,
    output [7:0]    LED,
    output  [7:0]    data,
    output  [14:0]   addr,
    output          t_r_data,
    output          t_r_addr,
    output          n_oe_trans,
    output          n_write,
    output          n_oe,
    output          n_ce
);

    reg reset = 1;

    assign n_oe_trans = 0; // turn on tranceivers
    assign t_r_data = 1; // transmit on data transceiver
    assign t_r_addr = 1; // transmit on addr transceiver

    assign LED = data;

    `ifdef TEST_OUTPUT

    reg [7:0] data_shift = 1'b1;

    wire [7:0] sram_data_read;
    wire [7:0] sram_data_write;

    reg [14:0] addr_shift = 1'b1;

    wire [14:0] sram_addr_read;
    wire [14:0] sram_addr_write;

    assign data = data_shift; // turn on all data pins
    assign addr = addr_shift; // turn on all data pins

    reg [18:0] counter;
    always @(posedge clk) begin
        counter <= counter + 1;
        if(&counter) begin
            data_shift <= {data_shift[6:0], data_shift[7]};
            addr_shift <= {addr_shift[13:0], addr_shift[7]};
        end
    end
    

//    `ifndef DEBUG
/* doesn't work - don't know why

    wire sram_data_pins_oe = 1;
    wire sram_addr_pins_oe = 1;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) data_pins [7:0] (
        .PACKAGE_PIN(data),
        .OUTPUT_ENABLE(sram_data_pins_oe),
        .D_OUT_0(sram_data_write),
        .D_IN_0(sram_data_read),
    );

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) addr_pins [14:0] (
        .PACKAGE_PIN(addr),
        .OUTPUT_ENABLE(sram_addr_pins_oe),
        .D_OUT_0(sram_addr_write),
        .D_IN_0(sram_addr_read),
    );
    */

 //   `endif

    `endif

    always @(posedge clk)
        reset <= 0;


endmodule

