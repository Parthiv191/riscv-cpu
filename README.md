# RISC-V RV32I CPU

32-bit RISC-V CPU (RV32I subset), single-cycle first, pipelined later.

## Design

- Top module: `riscv_top` (rtl/riscv_top.v)
- Interface / block descriptions: see the design doc
- Behavior: see the design doc

## Build & simulate

```bash
make lint          # check for issues
make sim TB=alu    # compile and run a block testbench (default: alu)
make wave TB=alu   # open waveform
```

## Verification

- [ ] ALU — per-op testbench
- [ ] Regfile — write/read, x0 behavior
- [ ] Imm_gen — all 5 immediate formats
- [ ] Control — decode table coverage
- [ ] Dmem — sync write / async read
- [ ] Top — integration programs t01-t08

## Notes

TODO: design decisions, gotchas, what I'd change.
