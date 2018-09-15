`default_nettype none
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
    output          trans_n_oe

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




endmodule

