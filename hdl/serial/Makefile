debug-serial:
	iverilog -o test serial_recv_tb.v uart_tx.v baudgen.v
	vvp test -fst
	gtkwave test.vcd gtk-serial.gtkw
