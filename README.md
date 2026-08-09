# riscv-cpu

A 32-bit RISC-V CPU (RV32I) built from scratch in Verilog. **Still in progress** — single-cycle version first, pipelined version once that's solid.

## Why

I wanted to actually understand how a CPU works below the instruction set and since I don't have the patience to wait for the computer architecture course I'm taking this fall, I'm building one myself. The early design (datapath, block breakdown) follows Harris & Harris' *Digital Design and Computer Architecture: RISC-V Edition* as a base and extends it to cover more of the ISA than the textbook subset. Not trying to invent a new architecture, just build a real one by hand and understand every wire in it.

## Where it stands

- **Done, implemented and tested:** ALU, control unit, register file — each has its own self-checking testbench
- **Interfaces defined, not implemented yet:** instruction memory, data memory, immediate generator
- **Next up:** wire everything into a top-level module and get actual hand-assembled programs running in simulation

Full instruction-by-instruction progress, the actual design decisions, and a few real bugs caught (and fixed) along the way are written up in [`docs/riscv_cpu_design_doc.md`](docs/riscv_cpu_design_doc.md).

## Layout

- `rtl/` — one file per block (ALU, regfile, immediate generator, control unit, instruction/data memory, top module)
- `tb/` — a self-checking testbench per block, written and passing before that block gets wired into anything else
- `docs/` — design doc, hand-drawn datapath, reference material
- `programs/` — hand-assembled test programs, once there's a top module to run them on

## Build & simulate

Icarus Verilog for simulation, Verilator for lint, Surfer for waveforms.

```bash
make lint          # verilator lint check
make sim TB=alu    # build + run a block's testbench (default: alu)
make wave TB=alu   # open the waveform in surfer
```

## What's next

Wire everything into `riscv_top.v`, get a handful of hand-assembled test programs passing end-to-end, then start on the pipelined version.
