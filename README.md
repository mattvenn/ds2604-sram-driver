# sram driver

drives an 8k x 8bit SRAM chip like the ds2064

    input wire             clk,                 // expecting 12Mhz, adjust WAIT_TIME if this changes
    input wire             reset,               // reset high

    // module control
    input wire             re,                  // read enable, otherwise write
    input wire             start,               // start a transaction
    output reg             ready,               // assert high when ready for a new transaction
    input  wire [12:0]     address,             // input address
    input  wire [7:0]      data_in,             // data to write here
    output reg [7:0]       data_out,            // data read is here

    // memory control
    output reg [12:0]      sram_address,        // sram address
    output reg [7:0]       sram_data_write,     // sram data pins out
    input  wire [7:0]      sram_data_read,      // sram data pins in
    output reg             sram_data_pins_oe,   // sram data pins direction, high for data out
    output wire            n_ce1,               // !ce1
    output wire            ce2,                 // ce2 - combination of these chip enables standby
    output wire            n_we,                // !we - low to write
    output wire            n_oe                 // !oe - low to enable outputs
    );

    parameter WAIT_TIME = 2;                    // parameter to set how long to wait before a read or write is done

# test bench

uses model of ds2064 with semi accurate timings for reads and writes
