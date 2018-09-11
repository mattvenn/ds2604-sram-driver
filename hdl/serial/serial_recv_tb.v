`include "baudgen.vh"
module test;
    localparam BAUD = `BTEST;

  reg clk = 0;
  reg [2:0] clk_div = 0;
  always  @(posedge clk)
    clk_div <= clk_div + 1;
  wire slw_clk2 = clk_div[2];
  wire slw_clk1 = clk_div[1];
  wire slw_clk0 = clk_div[0];

  reg reset = 1;

  reg rcv = 0;
  reg [39:0] rx_reg = 0;
  reg [31:0] tx_reg = 0;
  reg [2:0] rx_byte_cnt = 0;
  reg [31:0] addr = 0;
  reg [31:0] wr_d = 0;
  reg [7:0] txdata = 0;
  reg [7:0] rxdata = 0;
  reg tx_strb = 0;


      integer i;
    task send_data;
      input [39:0] data;
    begin
        for(i = 0; i < 5; i ++) begin
            rxdata <= data[39:32];
            data <= data << 8;
            rcv <= 1;
            # 2;
            rcv <= 0;
            # 2;
        end
        rcv <= 1;
        # 2;
        rcv <= 0;
        # 2;
    end
    endtask


  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     $dumpon;
     # 1
     reset <= 0;
     # 2

//    send_data({ADDR,32'd260});
    send_data({COUNT,32'd0});
    /*
    send_data({8'h02,32'hFF});
    send_data({8'h03,32'hFF});
    send_data({8'h04,32'h00});
    send_data({8'h01,32'hFF});
    */

     # 300
     wait(tx_bytes == 0 && ready==1);

     $finish;
  end

  reg start = 0;
  reg [2:0] tx_bytes = 0;
  reg last_ready = 0;

  // state machine states
  localparam ADDR = 8'h1;
  localparam LOAD = 8'h2;
  localparam WRITE = 8'h3;
  localparam READ = 8'h4;
  localparam READ_REQ = 8'h5;
  localparam COUNT = 8'h6;
  localparam CONST = 8'h7;

  reg [31:0] count = 260;

  always #1 clk = !clk;
  wire [7:0] cmd_byte = rx_reg[39:32];
  wire [31:0] data_bytes = rx_reg[31:0];
  reg rd_req = 0;
  reg wr_req = 0;
  reg [3:0] ready_shift = 0;
  always @(posedge clk)
    ready_shift <=  {ready, ready_shift[3:1]};

  always @(posedge clk) begin
    if (rcv) begin
        rx_reg <= {rx_reg[31:0], rxdata};
        rx_byte_cnt <= rx_byte_cnt + 1;
        if(rx_byte_cnt == 5) begin
            case(cmd_byte)
                ADDR:  begin addr <= data_bytes; tx_reg <= data_bytes; end
                LOAD:  begin wr_d <= data_bytes; tx_reg <= data_bytes; end
                //WRITE: begin wr_req_ser <= 1; tx_reg <= WRITE; end
                //READ:  tx_reg <= ram_data;
                READ_REQ: begin rd_req <= 1; tx_reg <= READ_REQ; end
                COUNT: begin tx_reg <= count; count <= count + 1; end
                CONST: tx_reg <= 32'h01010101;
                default: tx_reg <= count;
            endcase
            rx_byte_cnt <= 0;
            // only want 4, but couldn't get it to work, so read an extra in the control program
            tx_bytes <= 5;
        end
    end else begin
        rd_req <= 0;
        wr_req <= 0;
    end

    if (tx_bytes > 0 )begin
        if(ready) begin
            tx_strb <= 1'b1;
            txdata <= tx_reg[31:24]; 
        // tx_uart takes 2 clock cycles for ready to go low after starting, so have to only do this on transition
        end else if (~ready && ready_shift == 1) begin
            tx_reg <= tx_reg << 8;
            tx_bytes <= tx_bytes - 1;
        end 
    end else
        tx_strb <= 1'b0;

  end

    //tx_strb <= 1'b0;
    //-- Instanciar la unidad de transmision
    uart_tx #(.BAUD(BAUD)) TX0 ( .clk(clk),        //-- Reloj del sistema
             .rstn(~reset),     //-- Reset global (activo nivel bajo)
             .start(tx_strb),     //-- Comienzo de transmision
             .data(txdata),     //-- Dato a transmitir
             .ready(ready)    //-- Transmisor listo / ocupado
           );

endmodule


