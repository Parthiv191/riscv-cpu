# RISC-V CPU Makefile
#
# Usage: make sim TB=alu
#        make sim TB=top PROGRAM=programs/t01_addi.mem

SRC_DIR = rtl
TB_DIR  = tb

SRC     = $(wildcard $(SRC_DIR)/*.v)

TB      ?= alu
TB_SRC  = $(TB_DIR)/tb_$(TB).v
TOP     = tb_$(TB)

PROGRAM ?= program.mem

# Only tb_imem and tb_top actually declare a MEMFILE parameter -- passing
# -P for a parameter that doesn't exist on the target module is a hard
# elaboration error, so this flag only gets added for those two.
ifneq ($(filter $(TB),imem top run),)
MEMFILE_FLAG = -P$(TOP).MEMFILE=\"$(PROGRAM)\"
endif

SIM   = sim.vvp
WAVE  = waves.vcd

.PHONY: sim wave lint clean help $(SIM) $(WAVE)

help:
	@echo "Help:"
	@echo "  make lint                           - run Verilator lint on rtl/"
	@echo "  make sim TB=<block>                 - compile and run testbench for <block> (default: alu)"
	@echo "  make sim TB=<block> PROGRAM=<file>  - for TB=imem/top, load <file> into imem instead of program.mem"
	@echo "  make wave TB=<block>                - open waveform in Surfer"
	@echo "  make clean                          - remove build artifacts"

sim: $(WAVE)

$(SIM): $(SRC) $(TB_SRC)
	iverilog -g2012 -Wall -s $(TOP) $(MEMFILE_FLAG) -o $@ $^

$(WAVE): $(SIM)
	vvp $<

wave: $(WAVE)
	surfer $< &

lint:
	verilator --lint-only -Wall -Wno-DECLFILENAME $(SRC)

clean:
	rm -f $(SIM) $(WAVE)
