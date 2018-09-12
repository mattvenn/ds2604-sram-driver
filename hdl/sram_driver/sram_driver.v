/*

reads and writes to sram chip like the ds2064

*/
`default_nettype none
`timescale 1ns/1ns
module sram_driver (

    input wire             clk,                 // expecting 12Mhz, adjust WAIT_TIME if this changes
    input wire             reset,               // reset high

    // module control
    input wire             re,                  // read enable, otherwise write
    input wire             start,               // start a transaction
    output reg             ready,               // assert high when ready for a new transaction
    input  wire [12:0]     address,             // input address
    input  wire [7:0]      data_write,             // data to write here
    output reg [7:0]       data_read,            // data read is here

    // memory control
    output reg [12:0]      sram_address,        // sram address
    output reg [7:0]       sram_data_write,     // sram data pins out
    input  wire [7:0]      sram_data_read,      // sram data pins in
    output reg             sram_data_pins_oe,   // sram data pins direction, high for data out
    output wire            n_ce1,               // !ce1
    output wire            ce2,                 // ce2 - combination of these chip enables standby - this driver connects them both together
    output wire            n_we,                // !we - low to write
    output wire            n_oe                 // !oe - low to enable outputs
    );

    parameter WAIT_TIME = 2;                    // parameter to set how long to wait before a read or write is done
                                                // doc for ds2064 says 200ns max, so 3 cycles at 12MHz is enough

    // less confusing names for the io control of the sram chip
    reg ce = 0;
    reg oe = 0;
    reg we = 0;

    assign n_we = ! we;
    assign n_oe = ! oe;
    assign n_ce1 = ! ce;
    assign ce2 = ce;

    // state machine setup
    reg [3:0] state = STATE_WAIT;

    localparam N = $clog2(WAIT_TIME);
    reg [N-1:0] counter = 0;

    localparam STATE_WAIT = 0;
    localparam STATE_READ = 1;
    localparam STATE_WRITE = 2;

    always @(posedge clk) begin
        // sync reset
        if(reset) begin
            state <= STATE_WAIT;
            ready <= 0;
            data_read <= 0;
            sram_address <= 0;
            sram_data_pins_oe <= 0;
            ce <= 0;
            oe <= 0;
            we <= 0;
            counter <= 0;
        end else begin
        // state machine
        case( state )
            STATE_WAIT: begin
                ready <= 1;

                if(start) begin
                    ready <= 0;
                    sram_address <= address;
                    counter <= WAIT_TIME;

                    if(re) begin
                        sram_data_pins_oe <= 0;
                        state <= STATE_READ;
                        ce <= 1;
                        oe <= 1;
                        we <= 0;

                    end else begin
                        sram_data_pins_oe <= 1;
                        state <= STATE_WRITE;
                        sram_data_write <= data_write;
                        
                        ce <= 1;
                        oe <= 0;
                        we <= 1;
                    end
                end
            end

            STATE_READ: begin
                counter <= counter - 1;
                if(counter == 0) begin
                    ce <= 0;
                    ready <= 1;
                    data_read <= sram_data_read;
                    state <= STATE_WAIT;
                end
            end

            STATE_WRITE: begin
                counter <= counter - 1;
                if(counter == 0) begin
                    ce <= 0;
                    we <= 0;
                    ready <= 1;
                    state <= STATE_WAIT;
                end
            end

        endcase
        end
    end

endmodule
