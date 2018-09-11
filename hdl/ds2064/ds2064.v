/*

8K x 8 Static RAM

*/
`default_nettype none
`timescale 1ns/1ns
module ds2064 (

    input wire [12:0]       address,    // address pins of the RAM
    inout wire [7:0]        data,

    input wire              n_ce1,
    input wire              ce2,
    input wire              n_we,
    input wire              n_oe
    );

    parameter FILE = "sram.txt";
    initial $readmemh(FILE, sram);

    reg [7:0] sram [0:2**13-1];
    assign #200 data = (n_we && !n_oe && ce2 && !n_ce1) ? sram[address] : 8'bz;

    always @(*)
        if(!n_we && ce2 && !n_ce1)
            #200 sram[address] <= data;
endmodule
