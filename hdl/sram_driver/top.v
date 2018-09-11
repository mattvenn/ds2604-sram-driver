`default_nettype none

module top (
	input           clk,
    output [7:0]    LED,
    inout [7:0]     sram_data_pins,
    output [12:0]   sram_address,
    output          n_ce1,
    output          ce2,
    output          n_we,
    output          n_oe
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
    sram_driver #(.WAIT_TIME(2)) sram_driver_0(
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

    localparam STATE_START = 0;
    localparam STATE_READ = 1;
    localparam STATE_READ_WAIT = 2;
    localparam STATE_END = 4;

    reg [2:0] state = STATE_START;

    assign LED = address[12:5];
    
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

endmodule

