`default_nettype none
`define TEST_OUTPUT
//`define TEST_INPUT
module top (
	input           clk,
    output [7:0]    LED,
`ifdef TEST_INPUT
    input  [7:0]    data,
    input  [14:0]   addr,
    input          sram_n_write,
    input          sram_n_oe,
    input          sram_n_ce,
`elsif TEST_OUTPUT
    output  [7:0]    data,
    output  [14:0]   addr,
    output          sram_n_write,
    output          sram_n_oe,
    output          sram_n_ce,
`endif
    // these 3 control the tranceivers
    output          trans_tx_data,
    output          trans_tx_addr,
    output          trans_n_oe

);

    always @(posedge clk)
        reset <= 0;

    reg reset = 1;

    `ifdef TEST_OUTPUT

    assign LED = data;

    assign trans_n_oe = 0; // turn on tranceivers
    assign trans_tx_data = 1; // transmit on data transceiver
    assign trans_tx_addr = 1; // transmit on addr transceiver

    reg [7:0] data_shift = 1'b1;
    reg [2:0] ctrl_shift = 1'b1;
    reg [14:0] addr_shift = 1'b1;


    assign data = data_shift; // cycle data pins
    assign addr = addr_shift; // cycle addr pins
    assign {sram_n_write, sram_n_oe, sram_n_ce } = ctrl_shift; // cycle ctrl pins

    reg [18:0] counter;
    always @(posedge clk) begin
        counter <= counter + 1;
        if(&counter) begin
            data_shift <= {data_shift[6:0], data_shift[7]};
            addr_shift <= {addr_shift[13:0], addr_shift[7]};
            ctrl_shift <= {ctrl_shift[1:0], ctrl_shift[2]};
        end
    end
    

//    `ifndef DEBUG
/* doesn't work - don't know why

    wire [7:0] sram_data_read;
    wire [7:0] sram_data_write;
    wire [14:0] sram_addr_read;
    wire [14:0] sram_addr_write;

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

    `ifdef TEST_INPUT
    assign trans_n_oe = 0; // turn on tranceivers
    assign trans_tx_data = 0; // receive on data transceiver
    assign trans_tx_addr = 0; // receive on addr transceiver

//    assign LED = data[7:0];
//    assign LED = addr[7:0];
    //assign LED = addr[14:8];
    assign LED = { sram_n_write, sram_n_oe, sram_n_ce };
    `endif



endmodule

