//`define SIMPLE_WRITE
`define SERIAL_CONTROL

`default_nettype none
`include "../serial/baudgen.vh"

/* 
sram I bought from farnell is same pinout but

* A14 is not connected
* A13 is not connected


rottendoc schematic shows:

* !OE always gnd
* !cs1 is controlled by bus
* cs2 is tied high via 10k
* !we is tied high via 10k and attached to rw control

as all these control pins will have to be outputs for reading:

* drive !oe 0v
* drive cs2 (pin 26 - maps to A13) high
* !we is attached to sram driver
* !cs1 is attached to the sram driver

*/
module top (
	input           clk,
    output [7:0]    LED,

//    output  [7:0]    sram_data_write,
//    input   [7:0]   sram_data_read,
    inout  [7:0]    sram_data_pins,
    output  [12:0]   sram_address,

    output          sram_n_write,
    output          sram_n_oe,
    output          sram_n_ce1,
    output          sram_ce2,

    // serial
    input rx,
    output tx,

    // these 3 control the tranceivers
    output          trans_tx_data,
    output          trans_tx_addr,
    output          trans_n_oe
);

    reg reset = 1;

    always @(posedge clk)
        reset <= 0;

    `ifndef DEBUG
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) sram_data [7:0] (
        .PACKAGE_PIN(sram_data_pins),
        .OUTPUT_ENABLE(sram_data_pins_oe),
        .D_OUT_0(sram_data_write),
        .D_IN_0(sram_data_read),
    );
    `endif

    wire ram_ready;
    reg [12:0] ram_address = 0;
    reg [7:0] ram_data_write = 0;
    wire [7:0] ram_data_read;
    reg ram_re = 0;
    reg ram_start = 0;

    // tristate wires for sram chip
    wire sram_data_pins_oe;
    wire [7:0] sram_data_write;
    wire [7:0] sram_data_read;

    // sram driver
    sram_driver #(.WAIT_TIME(20)) sram_driver_0(
        .clk(clk),
        .reset(reset),

        // module interface
        .ready(ram_ready),
        .re(ram_re),
        .start(ram_start),
        .address(ram_address),
        .data_write(ram_data_write),
        .data_read(ram_data_read),

        // sram control pins
        .sram_address(sram_address),
        .sram_data_read(sram_data_read),
        .sram_data_write(sram_data_write),
        .sram_data_pins_oe(sram_data_pins_oe),
        .n_ce1(sram_n_ce1),
        .n_we(sram_n_write)
        //.n_oe(sram_n_oe) // schematic shows n_oe tied to gnd so don't ever try and drive it
    );

    assign sram_n_oe = 0; // tied to 0v in the rottendog
    assign sram_ce2 = 1;  // tied to 5v via 10k in rottendog

    `ifdef SIMPLE_WRITE 

    assign trans_n_oe = 0; // turn on tranceivers
    assign trans_tx_data = sram_data_pins_oe; // turn on tranceiver tx same time as enabling the data tx pins of the driver
    assign trans_tx_addr = 1; // transmit on addr transceiver

    localparam STATE_START = 0;
    localparam STATE_READ = 1;
    localparam STATE_READ_WAIT = 2;
    localparam STATE_END = 4;

    reg [2:0] state = STATE_START;

    
    always @(posedge clk) begin
        // sync reset
        if(reset) begin
            state <= STATE_START;
            ram_address <= 0;
        end else
        // state machine
        case( state )
            STATE_START: begin
                if(ram_ready == 1) begin
                    state <= STATE_READ;
                    ram_re <= 1;
                end
            end
            STATE_READ: begin
                ram_start <= 1;
                state <= STATE_READ_WAIT;
            end
            STATE_READ_WAIT: begin
                if(ram_ready == 1) begin
                    ram_start <= 0;
                    ram_address <= ram_address + 1;
                    //ram_data_write <= ram_address[7:0];
                    state <= STATE_READ;
                    if(ram_address == 14'h2000-1)
                        state <= STATE_END;
                end
            end
            STATE_END: begin
                state <= STATE_START;
            end
        endcase
    end

    assign LED = sram_data_pins;

    `endif

    `ifdef SERIAL_CONTROL

    assign LED = sram_data_read; //sram_address[7:0];

    assign trans_n_oe = 0; // turn on tranceivers
    assign trans_tx_data = sram_data_pins_oe; // turn on tranceiver tx same time as enabling the data tx pins of the driver
    assign trans_tx_addr = 1; // transmit on addr transceiver

    // serial port setup
    localparam BAUD = `B115200;

    wire rcv;
    reg tx_strb = 0;
    wire [7:0] rxdata;
    reg [7:0] txdata;
    wire tx_ready;
    wire logic_ce;

    reg [39:0] rx_reg = 0;
    reg [31:0] tx_reg = 0;
    reg [2:0] rx_byte_cnt = 0;
    reg [31:0] count = 0;

    // convenience buses for cmd and data bytes
    wire [7:0] serial_cmd = rx_reg[39:32];
    wire [31:0] serial_data_bytes = rx_reg[31:0];
    reg [31:0] serial_reply = 0;

    // bytes waiting to send
    reg [2:0] tx_bytes = 0;

    reg serial_cmd_rcvd;
    // need a delay between starting serial and it toggling the busy pin
    reg last_tx_ready = 0;
    always @(posedge clk)
        last_tx_ready <= tx_ready;

    reg send_reply = 0;

    // instantiate rx and tx
    uart_rx #(.BAUD(BAUD)) RX0 (.clk(clk),
           .rstn(!reset),
           .rx(rx),
           .rcv(rcv),
           .data(rxdata)
          );

    uart_tx #(.BAUD(BAUD)) TX0 ( .clk(clk),
             .rstn(!reset),
             .start(tx_strb),
             .data(txdata),
             .tx(tx),
             .ready(tx_ready)
           );

    // serial commands
    localparam ADDR = 8'h1;
    localparam LOAD = 8'h2;
    localparam WRITE = 8'h3;
    localparam READ = 8'h4;
    localparam READ_REQ = 8'h5;
    localparam COUNT = 8'h6;



    // on a serial command received, take action and make response
    always @(posedge clk)
        if(serial_cmd_rcvd) begin
            send_reply <= 1; // always send a reply
            case(serial_cmd)
                ADDR:  begin 
                    ram_address <= serial_data_bytes[12:0]; serial_reply <= serial_data_bytes; 
                end
                LOAD:  begin 
                    ram_data_write <= serial_data_bytes[7:0]; serial_reply <= serial_data_bytes;
                end
                WRITE: begin 
                    ram_re <= 0; ram_start <= 1; serial_reply <= WRITE;
                end
                READ:  begin 
                    serial_reply <= ram_data_read;
                end
                READ_REQ: begin 
                    ram_re <= 1; ram_start <= 1; serial_reply <= READ_REQ;
                end
                COUNT: begin 
                    serial_reply <= count; count <= count + 1; 
                end
                default: serial_reply <= serial_cmd;
            endcase
        end else begin
            // stop continuous writing/reading
            ram_start <= 0;
            // don't send reply
            send_reply <= 0;
        end


    // serial interface
    // first byte is a command (see above), second 4 make up an unsigned integer
    always @(posedge clk) begin
        if (rcv) begin
            rx_reg <= {rx_reg[31:0], rxdata};
            rx_byte_cnt <= rx_byte_cnt + 1;
            if(rx_byte_cnt == 4) begin
                serial_cmd_rcvd <= 1;
                rx_byte_cnt <= 0;
            end
        end else
            serial_cmd_rcvd <= 0;
    end

    // if a command is received, the tx data is queued in tx_reg
    // so while there are bytes to send, send each one
    always @(posedge clk) begin
        if(send_reply) begin
            tx_bytes <= 4;
            tx_reg <= serial_reply;
        end
        if(tx_bytes > 0)
            if(tx_ready) begin
                tx_strb <= 1'b1;
                txdata <= tx_reg[31:24]; 
            // tx_uart takes 2 clock cycles for ready to go low after starting, so have to only do this on transition
            end else if (~tx_ready && last_tx_ready) begin
                tx_reg <= tx_reg << 8;
                tx_bytes <= tx_bytes - 1;
                tx_strb <= 1'b0;
            end 
    end

    `endif

endmodule

