# riscv-cpu

Building a 32-bit RISC-V CPU (RV32I) from scratch in Verilog because I wanted
to actually understand what's going on under the hood instead of just taking
a computer architecture class's word for it. Doing this in two phases: a
single-cycle version first to get something that actually works, then a
5-stage pipelined version once that's solid.

Early design (the datapath, the block breakdown, the whole single-cycle
approach) is basically following Harris & Harris' *Digital Design and Computer
Architecture* — I'm using their RISC-V single-cycle datapath as the starting
point and extending it to cover more instructions than the textbook subset.
Not trying to reinvent the wheel on the architecture side, just trying to
actually build the thing with my own hands and understand every wire.

## Where things stand

Still very early. Right now this is mostly scaffolding — module interfaces
are stubbed out but most of the actual logic isn't written yet. The ALU is
the first block I'm actually implementing.

- Top module: `riscv_top` (`rtl/riscv_top.v`)
- Everything else lives in `rtl/`, one file per block (ALU, regfile, imm gen,
  control unit, imem, dmem)
- Each block gets its own testbench in `tb/` before it touches anything else

## Build & simulate

Using Icarus Verilog for simulation and Surfer for waveforms.

```bash
make lint          # verilator lint check
make sim TB=alu    # build + run a block's testbench (default: alu)
make wave TB=alu   # pop open the waveform in surfer
```

## Verification checklist

- [ ] ALU — every op, a handful of vectors each
- [ ] Regfile — write/read x1-x31, make sure x0 always reads 0
- [ ] Imm gen — all 5 immediate formats, hand-checked against the ref sheet
- [ ] Control unit — decode every supported opcode correctly
- [ ] Dmem — sync write, async read
- [ ] Full top-level integration — run some actual hand-assembled programs

## Notes to self

- Keep it Verilog-2005 for now, can revisit SystemVerilog features later
- No interrupts, no CSRs, no compressed instructions, no M extension — v1 is
  just enough RV32I to run real programs
- Once single-cycle is solid, rewrite (not refactor) for the pipelined
  version — cleaner than trying to bolt pipeline registers onto this
