# RISC-V CPU Makefile — Icarus + Verilator + Surfer
#
# Multi-module project: rtl/ holds design sources, tb/ holds one
# testbench per block (plus tb_top.v for full integration).
#
# Usage: make sim TB=alu   (default TB=alu)

SRC_DIR = rtl
TB_DIR  = tb

SRC     = $(wildcard $(SRC_DIR)/*.v)

TB      ?= alu
TB_SRC  = $(TB_DIR)/tb_$(TB).v
TOP     = tb_$(TB)

SIM   = sim.vvp
WAVE  = waves.vcd

.PHONY: sim wave lint clean help

help:
	@echo "Targets:"
	@echo "  make lint            - run Verilator lint on rtl/"
	@echo "  make sim TB=<block>  - compile and run testbench for <block> (default: alu)"
	@echo "  make wave TB=<block> - open waveform in Surfer"
	@echo "  make clean           - remove build artifacts"

sim: $(WAVE)

$(SIM): $(SRC) $(TB_SRC)
	iverilog -g2012 -Wall -s $(TOP) -o $@ $^

$(WAVE): $(SIM)
	vvp $<

wave: $(WAVE)
	surfer $< &

lint:
	verilator --lint-only -Wall -Wno-DECLFILENAME $(SRC)

clean:
	rm -f $(SIM) $(WAVE)
