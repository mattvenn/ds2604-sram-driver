`default_nettype none
`include "../serial/baudgen.vh"

module top (
	input           clk,
    output [7:0]    LED,
    inout [7:0]     sram_data_pins,
    output [12:0]   sram_address,
    output          n_ce1,
    output          ce2,
    output          n_we,
    output          n_oe,

    input rx,
    output tx
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

    // wires for sram chip
    wire sram_data_pins_oe;
    wire [7:0] sram_data_write;
    wire [7:0] sram_data_read;

    // sram driver
    sram_driver #(.WAIT_TIME(100)) sram_driver_0(
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
        .n_ce1(n_ce1),
        .ce2(ce2),
        .n_we(n_we),
        .n_oe(n_oe)
    );

    /*
    localparam STATE_START = 0;
    localparam STATE_READ = 1;
    localparam STATE_READ_WAIT = 2;
    localparam STATE_END = 4;

    reg [2:0] state = STATE_START;

    
    always @(posedge clk) begin
        // sync reset
        if(reset) begin
            state <= STATE_START;
            address <= 0;
        end else
        // state machine
        case( state )
            STATE_START: begin
                if(ready == 1) begin
                    state <= STATE_READ;
                    re <= 1;
                end
            end
            STATE_READ: begin
                start <= 1;
                state <= STATE_READ_WAIT;
            end
            STATE_READ_WAIT: begin
                if(ready == 1) begin
                    start <= 0;
                    address <= address + 1;
                    state <= STATE_READ;
                    if(address == 14'h2000-1)
                        state <= STATE_END;
                end
            end
            STATE_END: begin
                state <= STATE_END;
            end
        endcase
    end
    */

    assign LED = ram_address[12:5];

    // serial port setup
    localparam BAUD = `B115200;

    wire rcv;
    reg tx_strb;
    wire [7:0] rxdata;
    reg [7:0] txdata;
    wire tx_ready;
    wire logic_ce;

    reg [39:0] rx_reg = 0;
    reg [31:0] tx_reg = 0;
    reg [2:0] rx_byte_cnt = 0;
    reg [31:0] count = 0;

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

  // state machine states
  localparam ADDR = 8'h1;
  localparam LOAD = 8'h2;
  localparam WRITE = 8'h3;
  localparam READ = 8'h4;
  localparam READ_REQ = 8'h5;
  localparam COUNT = 8'h6;
  localparam CONST = 8'h7;


  // convenience buses for cmd and data bytes
  wire [7:0] cmd_byte = rx_reg[39:32];
  wire [31:0] data_bytes = rx_reg[31:0];

  // bytes waiting to send
  reg [2:0] tx_bytes = 0;

  // need a delay between starting serial and it toggling the busy pin
  reg last_tx_ready = 0;
  always @(posedge clk)
    last_tx_ready <= tx_ready;

  // serial interface
  // waits for 5 data bytes and 1 end byte
  // first byte is a command (see above), second 4 make up an unsigned integer
  always @(posedge clk) begin
    if (rcv) begin
        rx_reg <= {rx_reg[31:0], rxdata};
        rx_byte_cnt <= rx_byte_cnt + 1;
        if(rx_byte_cnt == 5) begin
            case(cmd_byte)
                ADDR:  begin ram_address <= data_bytes[12:0]; tx_reg <= data_bytes; end
                LOAD:  begin ram_data_write <= data_bytes[7:0]; tx_reg <= data_bytes; end
                WRITE: begin ram_re <= 0; ram_start <= 1; tx_reg <= WRITE; end
                READ:  tx_reg <= ram_data_read;
                READ_REQ: begin ram_re <= 1; ram_start <= 1; tx_reg <= READ_REQ; end
                COUNT: begin tx_reg <= count; count <= count + 1; end
                CONST: tx_reg <= 32'd259;
                default: tx_reg <= count;
            endcase
            rx_byte_cnt <= 0;
            // only want 4, but couldn't get it to work, so read an extra in the control program
            tx_bytes <= 5;
        end
    end else begin
        ram_start <= 0;
    end

    // if a command is received, the tx data is queued in tx_reg
    // so while there are bytes to send, send each one
    if (tx_bytes > 0 )begin
        if(tx_ready) begin
            tx_strb <= 1'b1;
            txdata <= tx_reg[31:24]; 
        // tx_uart takes 2 clock cycles for ready to go low after starting, so have to only do this on transition
        end else if (~tx_ready && last_tx_ready) begin
            tx_reg <= tx_reg << 8;
            tx_bytes <= tx_bytes - 1;
        end 
    end else
        tx_strb <= 1'b0;

  end

endmodule

