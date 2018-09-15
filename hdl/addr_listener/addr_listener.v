`default_nettype none
`include "../serial/baudgen.vh"
module top (
	input           clk,

    output [7:0]    LED,
    input  [7:0]    sram_data_pins,
    input  [12:0]   sram_address,
    input          sram_n_write,
    input          sram_n_ce1,

    // these 3 control the tranceivers
    output          trans_tx_data,
    output          trans_tx_sram_address,
    output          trans_n_oe,

    // serial
    input rx,
    output tx

);
    
    wire sram_ce = ! sram_n_ce1;
    wire sram_write = ! sram_n_write;

    always @(posedge clk)
        reset <= 0;

    reg reset = 1;

    assign trans_n_oe = 0; // turn on tranceivers
    assign trans_tx_data = 0; // receive on data transceiver
    assign trans_tx_sram_address = 0; // receive on addr transceiver

    reg [7:0] leds = 0;
    reg [12:0] address = 0;

    reg [3:0] ce_counter = 0;
    localparam WAIT = 1;

    reg [23:0] high_score = 0;

    always @(clk) begin
        if(sram_ce) begin
            if(ce_counter < WAIT)
                ce_counter <= ce_counter + 1;
            else if(ce_counter == WAIT) begin
                case(sram_address)
                    sc_100_k:
                        high_score[23:20] <= sram_data_pins[3:0];
                    sc_10_k:
                        high_score[19:16] <= sram_data_pins[3:0];
                    sc_1_k:
                        high_score[15:12] <= sram_data_pins[3:0];
                    sc_100:
                        high_score[11: 8] <= sram_data_pins[3:0];
                    sc_10:
                        high_score[ 7: 4] <= sram_data_pins[3:0];
                    sc_1:
                        high_score[ 3: 0] <= sram_data_pins[3:0];
                endcase
            end
        else
            ce_counter <= 0;
        end 
    end


    // 030290
    // with 10k and 1k
    // 7:4 = 1
    // 3:0 = 0
    localparam sc_100_k = 13'h1148; // 00
    localparam sc_10_k  = 13'h1149; // 03
    localparam sc_1_k   = 13'h114a; // 00
    localparam sc_100   = 13'h114b; // 02
    localparam sc_10    = 13'h114c; // 09
    localparam sc_1     = 13'h114d; // 00

    assign LED = leds;

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
    localparam SCORE = 8'h7;

    // on a serial command received, take action and make response
    always @(posedge clk)
        if(serial_cmd_rcvd) begin
            send_reply <= 1; // always send a reply
            case(serial_cmd)
                SCORE:  begin 
                    serial_reply <= high_score; 
                end
                default: serial_reply <= serial_cmd;
            endcase
        end else begin
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

endmodule

