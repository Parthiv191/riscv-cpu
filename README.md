# riscv-cpu

A 32-bit RISC-V CPU (RV32I) built from scratch in Verilog. The single-cycle version is complete and verified; a 5-stage pipelined version is next, so this is still an ongoing project overall.

## Why

I wanted to actually understand how a CPU works below the instruction set and since I don't have the patience to wait for the computer architecture course I'm taking this fall, I'm building one myself. The early design (datapath, block breakdown) follows Harris & Harris' *Digital Design and Computer Architecture: RISC-V Edition* as a base and extends it to cover more of the ISA than the textbook subset. Not trying to invent a new architecture, just build a real one by hand and understand every wire in it.

## Where it stands

**Single-cycle core: done.** All 7 blocks (ALU, control unit, register file, instruction memory, data memory, immediate generator, top-level module) are implemented, each with its own self-checking testbench, and `make lint` passes clean with zero Verilator warnings. Every one of the 31 supported RV32I instructions has actually run through the real `riscv_top` datapath, not just been decoded in isolation — 8 hand-assembled test programs cover arithmetic, load/store, all 6 branch conditions, both jump forms, both upper-immediate ops, and a small real program that sums an array in memory.

**Next up:** the 5-stage pipelined version — forwarding, hazard detection, the usual.

Full instruction-by-instruction progress, the actual design decisions, and a few real bugs caught (and fixed) along the way are written up in [`docs/riscv_cpu_design_doc.md`](docs/riscv_cpu_design_doc.md).

## Layout

- `rtl/` — one file per block (ALU, regfile, immediate generator, control unit, instruction/data memory, top module)
- `tb/` — a self-checking testbench per block, plus `tb_top`/`tb_run` for full-CPU integration
- `programs/` — 8 hand-assembled test programs (`t01`-`t08`) covering every instruction
- `docs/` — design doc, hand-drawn datapath, reference material

## Build & simulate

Icarus Verilog for simulation, Verilator for lint, Surfer for waveforms.

```bash
make lint                                            # verilator lint check
make sim TB=alu                                      # build + run a block's testbench (default: alu)
make sim TB=run PROGRAM=programs/t05_sum_array.mem   # run a specific program through the full CPU
make wave TB=run PROGRAM=programs/t05_sum_array.mem  # same, then open the waveform in surfer
```

## What's next

Start on the pipelined version — same ISA, 5-stage IF/ID/EX/MEM/WB, forwarding and hazard handling.
