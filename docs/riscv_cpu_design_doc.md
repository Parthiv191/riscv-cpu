# RISC-V RV32I CPU — Design Doc

**Author:** Parthiv Patel
**Started:** 6/14/26
**Status:** DRAFT — scaffolding is up, ALU is the first thing actually getting coded

---

## 1. Project Overview

Building a 32-bit RISC-V CPU (RV32I subset) in Verilog, from scratch. Main
goal right now is a **single-cycle CPU** — every instruction finishes in one
clock cycle, no pipeline, nothing fancy. Just get it correct. Once that's
solid I'll move on to a pipelined version (see Section 12 for what that
looks like and what happens in between).

Reference for the single-cycle datapath is Harris & Harris' *Digital Design
and Computer Architecture: RISC-V Edition*, Ch. 7 — I'm using their
single-cycle datapath as the starting point and extending it to cover more
of the ISA than the textbook subset does.

### 1.1 Success Criteria

- Passes a hand-written test program suite covering every supported instruction
- Passes a small end-to-end program (array sum, GCD, factorial, something like that) in sim
- Synthesizes cleanly with Verilator (no lint warnings)
- Stretch: gets it running on a Basys 3 with LEDs/switches as I/O

### 1.2 Non-Goals (for now)

- Exception / trap handling
- CSRs (beyond whatever's strictly needed to run programs)
- Interrupts
- Caches
- MMU / virtual memory
- Compressed (RVC) instructions
- Multiply/divide (RV32M)
- Branch prediction (predict-not-taken + flush is fine)
- Multi-cycle memory (memory is single-cycle for simplicity)

### 1.3 Constraints

- **Time:** originally budgeted ~5 weeks for single-cycle. Already past that
  and still on scaffolding, so that estimate was optimistic — not stressing
  about it, just noting reality.
- **Tools:** Icarus Verilog for sim, Surfer for waveforms, Vivado (via SSH to
  the Ubuntu box) for Basys 3 stuff later.
- **Language:** Verilog-2005. Might pull in SystemVerilog features (`logic`,
  `always_ff`) once v1 actually works.

---

## 2. ISA Subset

Supporting enough of RV32I to run real, non-trivial programs.

### 2.1 Instructions Supported (v1) — 31 total

| Category | Instructions |
|---|---|
| R-type arithmetic | `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu` |
| I-type arithmetic | `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`, `slti`, `sltiu` |
| Load | `lw` |
| Store | `sw` |
| Branch | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` |
| Jump | `jal`, `jalr` |
| Upper immediate | `lui`, `auipc` |

### 2.2 Instruction Progress Tracker

The actual thing I'll keep updated as I work. Four checkpoints per
instruction: sketched on the hand-drawn datapath, control signals worked out
(has a row in the Section 6 table), coded in `rtl/*.v`, and has a passing
testbench vector.

Legend: ✅ done · 🔧 in progress · ⬜ not started

| Instruction | Type | Datapath | Control | RTL | Testbench |
|---|---|---|---|---|---|
| `add`   | R | ⬜ | ✅ | 🔧 | ⬜ |
| `sub`   | R | ⬜ | ✅ | 🔧 | ⬜ |
| `and`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `or`    | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `xor`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `sll`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `srl`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `sra`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `slt`   | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `sltu`  | R | ⬜ | ⬜ | 🔧 | ⬜ |
| `addi`  | I | ⬜ | ✅ | ⬜ | ⬜ |
| `andi`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `ori`   | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `xori`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `slli`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `srli`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `srai`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `slti`  | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `sltiu` | I | ⬜ | ⬜ | ⬜ | ⬜ |
| `lw`    | Load | ⬜ | ✅ | ⬜ | ⬜ |
| `sw`    | Store | ⬜ | ✅ | ⬜ | ⬜ |
| `beq`   | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `bne`   | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `blt`   | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `bge`   | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `bltu`  | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `bgeu`  | Branch | ⬜ | ✅ | ⬜ | ⬜ |
| `jal`   | Jump | ⬜ | ✅ | ⬜ | ⬜ |
| `jalr`  | Jump | ⬜ | ✅ | ⬜ | ⬜ |
| `lui`   | Upper-imm | ⬜ | ✅ | ⬜ | ⬜ |
| `auipc` | Upper-imm | ⬜ | ✅ | ⬜ | ⬜ |

`rtl/alu.v` is done and correctly matches the `{funct7[5], funct3}` scheme
(see 5.1) for all 10 ops. Bumped the RTL column below to 🔧 across the board
— the ALU logic itself is complete, but these aren't "instruction done"
until `control.v` actually routes opcode/funct3/funct7 into `alu_op`.

Byte/halfword loads and stores (`lb`, `lh`, `lbu`, `lhu`, `sb`, `sh`) and
trap-related instructions (`fence`, `ecall`, `ebreak`) are **not** in this
tracker — they're deferred, see Section 12.

### 2.3 Register Conventions

- 32 general-purpose registers, `x0`–`x31`, 32 bits each
- `x0` hardwired to zero: reads always return 0, writes silently discarded
- Not enforcing ABI/calling-convention stuff in hardware — that's a compiler problem, not mine

---

## 3. Microarchitecture Overview

- One instruction per clock cycle, start to finish
- Combinational IMEM, regfile read ports, ALU, DMEM read
- Synchronous writes to regfile, DMEM, and PC (all on `posedge clk`)
- Reference datapath: Harris & Harris Figure 7.11, adapted for the extended instruction set

### 3.1 Memory Model

- Harvard architecture (separate IMEM and DMEM)
- Both BRAM-backed, single-cycle access
- IMEM: read-only, preloaded via `$readmemh` from a `.mem` file at sim start
- DMEM: read/write, zero-initialized
- Both word-addressed internally, byte-addressed externally (standard RISC-V convention)

**Address map (v1):**
- `0x0000_0000 – 0x0000_FFFF` — Instruction memory (64 KB)
- `0x1000_0000 – 0x1000_FFFF` — Data memory (64 KB)
- `0x2000_0000 – 0x2000_000F` — Memory-mapped I/O (reserved for Basys 3 LEDs/switches)

### 3.2 Reset Behavior

- PC resets to `0x0000_0000` on `rst = 1` (synchronous, active-high)
- Register file is NOT reset — reads before writes just return whatever's there (0 from x0, garbage/zero from BRAM init elsewhere)
- DMEM contents not reset — assume BRAM starts at 0

---

## 4. Datapath

**[TBD — haven't drawn this yet.]** Starting point is Harris & Harris Figure
7.11. Known modifications from the textbook subset:

- Extend `ImmSrc` to handle all 5 immediate types (I, S, B, U, J), not just I/S/B
- Add the AUIPC path (immediate + PC → result)
- Add JAL/JALR support (write PC+4 to rd, jump)
- Handle all 6 branch conditions, not just `beq`

### 4.1 Key Wires and Widths

| Wire | Width | Description |
|---|---|---|
| `pc` | 32 | Current program counter |
| `pc_next` | 32 | Next PC (mux: PC+4, branch target, or jump target) |
| `pc_plus4` | 32 | PC + 4 (return addresses, sequential flow) |
| `instr` | 32 | Current instruction from IMEM |
| `rs1_addr`, `rs2_addr` | 5 | Register file read addresses |
| `rd_addr` | 5 | Register file write address |
| `rs1_data`, `rs2_data` | 32 | Register file read data |
| `imm` | 32 | Sign-extended immediate |
| `alu_a`, `alu_b` | 32 | ALU operands |
| `alu_result` | 32 | ALU output |
| `alu_zero` | 1 | ALU zero flag (for BEQ) |
| `mem_addr` | 32 | Data memory address (usually `alu_result`) |
| `mem_wdata` | 32 | Data memory write data (`rs2_data`) |
| `mem_rdata` | 32 | Data memory read data |
| `result` | 32 | Value written back to regfile (mux: alu_result, mem_rdata, pc_plus4) |

---

## 5. Block-by-Block Descriptions

### 5.1 ALU (`rtl/alu.v`)

Arithmetic/logic for R-type, I-type, load/store address calc, and branch comparison.

```verilog
module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_op,
    output [31:0] result,
    output        zero          // 1 when result == 0
);
```

| `alu_op` | Operation | Description |
|---|---|---|
| 0000 | ADD | a + b |
| 1000 | SUB | a - b |
| 0001 | SLL | a << b[4:0] |
| 0010 | SLT | signed(a) < signed(b) ? 1 : 0 |
| 0011 | SLTU | unsigned(a) < unsigned(b) ? 1 : 0 |
| 0100 | XOR | a ^ b |
| 0101 | SRL | a >> b[4:0] (logical) |
| 1101 | SRA | a >>> b[4:0] (arithmetic) |
| 0110 | OR | a \| b |
| 0111 | AND | a & b |

**Design decision: `alu_op` is literally `{funct7[5], funct3}` — not an
arbitrary enum.** RISC-V's real R-type encoding already assigns funct3 =
000/001/010/011/100/101/110/111 to add/sll/slt/sltu/xor/srl/or/and, and
funct7[5] (`instr[30]`) is 1 only for sub/sra. So the table above is just
`instr[30]` concatenated with `instr[14:12]` — no lookup table needed for
these ops in the control unit, just wire the bits through (with one
exception, see 5.6).

Notes:
- Use `$signed()` for SLT and SRA
- Force `b[4:0]` on all shifts so a runaway shift amount can't happen
- `zero` is combinational, driven from `result == 32'b0`

### 5.2 Register File (`rtl/regfile.v`)

32 × 32-bit storage, 2 read ports, 1 write port.

```verilog
module regfile (
    input         clk,
    input         we,
    input  [4:0]  rs1_addr, rs2_addr, rd_addr,
    input  [31:0] rd_data,
    output [31:0] rs1_data, rs2_data
);
```

- Reads are async/combinational
- Writes are sync on `posedge clk` when `we` is high
- Reads from `x0` always return 0 (mux the output)
- Writes to `x0` are effectively a no-op (can silently drop them, or let them write and just never read it back — either works)

### 5.3 Instruction Memory (`rtl/imem.v`)

```verilog
module imem (
    input  [31:0] addr,
    output [31:0] instr
);
```

- Async/combinational lookup
- Word-aligned: uses `addr[15:2]` as the internal index (drops bottom 2 bits)
- Preloaded with `$readmemh("program.mem", memory_array)` in an `initial` block
- 64 KB (16K instructions)
- Keep async for now — convert to sync-read BRAM when the pipeline phase starts

### 5.4 Data Memory (`rtl/dmem.v`)

```verilog
module dmem (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
```

- Sync write on `posedge clk` when `we` is high
- Async read
- Word-only in v1, no byte-enables
- 64 KB

### 5.5 Immediate Generator (`rtl/imm_gen.v`)

```verilog
module imm_gen (
    input  [31:0] instr,
    input  [2:0]  imm_src,
    output [31:0] imm
);
```

| `imm_src` | Format | Bit layout |
|---|---|---|
| 000 | I-type | `{{20{instr[31]}}, instr[31:20]}` |
| 001 | S-type | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| 010 | B-type | `{{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` |
| 011 | U-type | `{instr[31:12], 12'b0}` |
| 100 | J-type | `{{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` |

Branch/jump immediates have an implicit LSB of 0 (instructions are 4-byte
aligned), which is why B/J have `1'b0` tacked on at position `[0]`.

**This is the module most likely to have bugs.** Write a testbench that hits
every format with several vectors before wiring it up. Check bit-by-bit
against the ref sheet.

### 5.6 Control Unit (`rtl/control.v`)

Decodes opcode/funct3/funct7 into every control signal.

```verilog
module control (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input        alu_zero,
    output       reg_write,
    output       mem_write,
    output       mem_to_reg,     // WB mux: 0=alu, 1=mem, 2=pc+4
    output [1:0] result_src,
    output       alu_src_a,      // 0=rs1, 1=pc (AUIPC)
    output       alu_src_b,      // 0=rs2, 1=imm
    output [3:0] alu_op,
    output [2:0] imm_src,
    output [1:0] pc_src          // 0=pc+4, 1=branch, 2=jal, 3=jalr
);
```

See Section 6 for the full signal table.

**`alu_op` generation (per the 5.1 decision):** for R-type ops and the
I-type shifts (`slli`/`srli`/`srai`), `alu_op = {instr[30], instr[14:12]}`
directly — no per-instruction lookup needed, the RISC-V encoding already
gives the right bits. The one exception: **`addi`** also has
`funct3 = 000` (same slot as add/sub), but `instr[30]` for `addi` is just
part of its immediate, not a real subtract flag — force that top bit to 0
for `addi` specifically, or equivalently only pass `funct7[5]` through when
`opcode` is R-type, or I-type with `funct3 == 101` (the shift slot).

For everything else — `lw`, `sw`, `jalr`, `auipc` (always ADD), and
branches (SUB for beq/bne, SLT for blt/bge, SLTU for bltu/bgeu, picked off
branch `funct3`) — `alu_op` is set directly by the control unit's own logic,
not derived from the instruction's funct3/funct7 bits.

### 5.7 Top Module (`rtl/riscv_top.v`)

Instantiates all the blocks, holds the PC register and muxes.

```verilog
module riscv_top (
    input         clk,
    input         rst,
    output [31:0] debug_pc,
    output [31:0] debug_instr
);
```

Contains: PC register (sync reset), PC+4 adder, next-PC mux (PC+4 / branch /
jal / jalr target), branch target adder, all block instantiations, result
writeback mux.

---

## 6. Control Signals

**[TBD — 14 of 31 rows filled in, rest pending.]** Note: the `alu_op`
column below is written as a mnemonic (ADD/SUB/SLT/...) for readability, but
for R-type and I-type-shift rows it's not actually a per-row lookup in
`control.v` — it's generated directly from `{funct7[5], funct3}` per 5.6.
The mnemonics in this column only need real decode logic for the rows where
`alu_op` isn't derived that way: `lw`/`sw`/`jalr`/`auipc` (always ADD) and
the branches (SUB/SLT/SLTU based on branch `funct3`).

| Instruction | `reg_write` | `mem_write` | `result_src` | `alu_src_a` | `alu_src_b` | `alu_op` | `imm_src` | `pc_src` |
|---|---|---|---|---|---|---|---|---|
| `add`   | 1 | 0 | ALU  | rs1 | rs2 | ADD  | – | pc+4 |
| `sub`   | 1 | 0 | ALU  | rs1 | rs2 | SUB  | – | pc+4 |
| `addi`  | 1 | 0 | ALU  | rs1 | imm | ADD  | I | pc+4 |
| `lw`    | 1 | 0 | MEM  | rs1 | imm | ADD  | I | pc+4 |
| `sw`    | 0 | 1 | –    | rs1 | imm | ADD  | S | pc+4 |
| `beq`   | 0 | 0 | –    | rs1 | rs2 | SUB  | B | branch if zero |
| `bne`   | 0 | 0 | –    | rs1 | rs2 | SUB  | B | branch if !zero |
| `blt`   | 0 | 0 | –    | rs1 | rs2 | SLT  | B | branch if result |
| `bge`   | 0 | 0 | –    | rs1 | rs2 | SLT  | B | branch if !result |
| `bltu`  | 0 | 0 | –    | rs1 | rs2 | SLTU | B | branch if result |
| `bgeu`  | 0 | 0 | –    | rs1 | rs2 | SLTU | B | branch if !result |
| `jal`   | 1 | 0 | PC+4 | – | – | – | J | jal target |
| `jalr`  | 1 | 0 | PC+4 | rs1 | imm | ADD | I | jalr target |
| `lui`   | 1 | 0 | ALU  | 0 | imm | ADD (or passthrough) | U | pc+4 |
| `auipc` | 1 | 0 | ALU  | pc | imm | ADD | U | pc+4 |

Still need: `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`, `andi`,
`ori`, `xori`, `slli`, `srli`, `srai`, `slti`, `sltiu`.

---

## 7. Verification Plan

### 7.1 Per-Block Testbenches

| Block | Test cases |
|---|---|
| ALU | Every op, 4 pattern classes each: pos-pos, pos-neg, neg-neg, boundaries (0, all-ones, MSB set). ~40 vectors. |
| Regfile | Write x1–x31, read back. Verify x0 always reads 0. Verify write-to-x0 is a no-op. |
| Imem | Preload a known pattern, verify readback at every address. |
| Dmem | Write + read at several addresses. Verify sync write, async read. |
| Imm_gen | 3 vectors per format × 5 formats = 15+ vectors, checked against the ref sheet. |
| Control | Exhaustive over every supported opcode, compared against Section 6. |

### 7.2 Integration Tests

Hand-assembled programs, one `.mem` file each under `programs/`:

1. `t01_addi.mem` — basic arithmetic
2. `t02_load_store.mem` — store then load into a different register
3. `t03_branch.mem` — loop with `beq`/`bne`, branch taken/not-taken
4. `t04_jump.mem` — `jal` to a label, verify return address in `rd`
5. `t05_sum_array.mem` — sum 10 numbers in memory
6. `t06_all_r_type.mem` — exercise every R-type
7. `t07_all_i_type.mem` — exercise every I-type
8. `t08_lui_auipc.mem` — verify upper-immediate ops

Pass criterion: after the program halts (last instruction is `jal x0, 0`,
i.e. infinite self-loop), dump the register file and compare against
expected values.

### 7.3 RISC-V Test Suite (stretch goal)

`riscv-tests` has thousands of ISA compliance tests. Try a subset once v1 works.

---

## 8. File Structure (current)

```
riscv_cpu/
├── README.md
├── Makefile
├── .gitignore
├── rtl/
│   ├── alu.v          (in progress)
│   ├── regfile.v       (stub)
│   ├── imm_gen.v        (stub)
│   ├── control.v        (stub)
│   ├── imem.v           (stub)
│   ├── dmem.v           (stub)
│   └── riscv_top.v      (stub)
├── tb/
│   ├── tb_alu.v         (stub)
│   ├── tb_regfile.v     (stub)
│   ├── tb_imm_gen.v     (stub)
│   ├── tb_control.v     (stub)
│   ├── tb_imem.v        (stub)
│   ├── tb_dmem.v        (stub)
│   └── tb_top.v         (stub)
├── programs/           (empty — .mem test programs go here later)
└── docs/
    ├── riscv_cpu_design_doc.md        (this document)
    ├── Immediate Coding Diagram.png   (reference, gitignored)
    ├── Ref Sheet.pdf                  (reference, gitignored)
    └── riscv-unprivileged.pdf         (reference, gitignored)
```

---

## 9. Open Questions / Notes

Running log of stuff I need to decide, revisit, or watch out for.

- How to bootstrap: does PC really just start at 0, or does the program need a "startup" sequence?
- For JALR, spec says target = `(rs1 + imm) & ~1` (clear bit 0). Make sure the implementation actually does this.
- For branches: is `alu_zero` + `alu_result[0]` (for SLT-based branches) enough, or do I need a dedicated branch comparator?
- When it's time to pipeline: rewrite from scratch, or refactor the single-cycle version? Leaning rewrite — cleaner than bolting pipeline registers onto something that wasn't built for it.
- **Watch this one when writing `control.v`:** don't let `instr[30]` pass through as the alu_op top bit for `addi` — that bit is part of `addi`'s immediate, not a sub flag. Only R-type and I-type-shift (`slli`/`srli`/`srai`) should use `funct7[5]` for real. Getting this wrong means `addi` silently becomes `sub` for certain immediate values.

---

## 10. Timeline (rough, and already slipping)

| Week | Milestone |
|---|---|
| 1 | ALU + regfile + testbenches passing *(currently here)* |
| 2 | Imm_gen + control + imem/dmem, all block-tested |
| 3 | Top module wired, t01–t04 pass in sim |
| 4 | t05–t08 pass; start pipeline design |
| 5 | Pipeline datapath complete in sim (no hazards yet) |
| 6+ | Forwarding, stalls, flushes; all t0X programs pass on pipelined version |

---

## 11. References

- Harris & Harris, *Digital Design and Computer Architecture: RISC-V Edition*, Ch. 7 — main reference for the single-cycle datapath, basically my bible right now
- RISC-V Instruction Set Manual, Volume I (Unprivileged), latest ratified version
- Reference sheet (H&H Figure B.1 + Table B.1 — printed and taped to my monitor)
- darkriscv (github.com/darklife/darkriscv) — read the top module for ideas
- picorv32 (github.com/YosysHQ/picorv32) — state machine reference

---

## 12. Later On: Pipelining + What Happens In Between

Not building this yet — just leaving notes so I don't lose the plan.

### 12.1 Between single-cycle working and starting the pipeline

Stuff to pick up once t01–t08 all pass on the single-cycle version, before
touching pipeline registers:

- Byte/halfword loads and stores: `lb`, `lh`, `lbu`, `lhu`, `sb`, `sh` (needs byte-lane logic in dmem)
- Trap-related instructions: `fence`, `ecall`, `ebreak`
- Maybe adopt some SystemVerilog features (`logic`, `always_ff`) if it's not too disruptive
- Stretch goal: get it running on the Basys 3 with LEDs/switches

### 12.2 Pipeline (Phase 2) skeleton

Stages: **IF → ID → EX → MEM → WB**

- IF — PC → IMEM → IF/ID register
- ID — decode + regfile read + immediate gen → ID/EX register
- EX — ALU execution → EX/MEM register
- MEM — data memory access → MEM/WB register
- WB — write result to regfile

**Pipeline register contents:** TBD — this is the #1 design decision for the pipeline, need to enumerate exactly what each register holds.

**Hazards:**
- Data: EX/MEM → EX forwarding, MEM/WB → EX forwarding, load-use stall (1 cycle when load is in EX and the dependent instruction is in ID)
- Control: predict-not-taken, flush IF/ID and ID/EX on a taken branch
- Structural: none expected (Harvard memory)

**Forwarding unit / hazard detection unit:** TBD, design after the basic 5-stage datapath is working with no hazard handling.

---

## Changelog

- **6/14/26** — Initial draft created from scaffold.
- **7/18/26** — Fixed ALU op table descriptions, added rtl/tb file scaffold.
- **7/28/26** — Reworked doc to focus on single-cycle only, added the
  instruction progress tracker, moved pipeline notes to Section 12, started
  tracking this file in git.
