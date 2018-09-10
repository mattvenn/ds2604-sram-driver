PROJ = sram_driver
PIN_DEF = icestick.pcf
DEVICE = hx1k

SRC = top.v sram_driver.v

all: $(PROJ).bin
#all: $(PROJ).rpt $(PROJ).bin

%.blif: $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug:
	iverilog -o sram_driver sram_driver.v sram_driver_tb.v ../ds2064/ds2064.v
	vvp sram_driver -fst
	gtkwave test.vcd gtk-sram_driver.gtkw

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
