PROJ = sram_driver
PIN_DEF = 8k.pcf
DEVICE = hx8k
PACKAGE = ct256

SRC = top.v sram_driver.v

all: $(PROJ).bin
#all: $(PROJ).rpt $(PROJ).bin

%.blif: $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

%.asc: $(PIN_DEF) %.blif
	arachne-pnr --device 8k --package $(PACKAGE) -p $^ -o $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug:
	iverilog -o sram_driver sram_driver.v sram_driver_tb.v ../ds2064/ds2064.v
	vvp sram_driver -fst
	gtkwave test.vcd gtk-sram_driver.gtkw

debug-top:
	iverilog -DDEBUG -o top sram_driver.v top.v top_tb.v ../ds2064/ds2064.v
	vvp top -fst
	gtkwave test.vcd gtk-top.gtkw

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
