PROJ = pcb_test
PIN_DEF = 8k.pcf
DEVICE = hx8k
PACKAGE = ct256

SRC = top.v 

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

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
