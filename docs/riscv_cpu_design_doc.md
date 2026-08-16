# RISC-V RV32I CPU — Design Notes

Building a 32-bit RISC-V CPU (RV32I subset) in Verilog, from scratch — single-cycle first, pipelined later. Base datapath follows Harris & Harris' *Digital Design and Computer Architecture: RISC-V Edition* (Ch. 7), extended to cover more of the ISA than the textbook subset.

---

## 1. Goals & Scope

- Pass a hand-written test suite covering every supported instruction and succesfully run capable programs
- Clean Verilator lint
- Implement on FPGA and use leds and swtiches as I/O
- Covering full RV32I for v1; maybe M/C/V extensions later

**Not doing in v1:** exception/trap handling, CSRs beyond the bare minimum, interrupts, caches, MMU, compressed instructions, RV32M, branch prediction, multi-cycle memory.

**Tools/constraints:** Icarus Verilog + Surfer for sim, Vivado for Basys 3 later. Currently written in Verilog-2005 with plans to conver to SystemVerilog once single-cycle actually works (see Section 7).

---

## 2. Instructions & Progress

31 instructions:

| Category | Instructions |
|---|---|
| R-type arithmetic | `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu` |
| I-type arithmetic | `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`, `slti`, `sltiu` |
| Load | `lw` |
| Store | `sw` |
| Branch | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` |
| Jump | `jal`, `jalr` |
| Upper immediate | `lui`, `auipc` |

Byte/halfword loads/stores and trap instructions (`fence`/`ecall`/`ebreak`) are deferred — see Section 7.

`x0` is hardwired to 0 (reads always 0, writes discarded). Not enforcing ABI/calling-convention stuff in hardware.

**Per-instruction** — sketched on the datapath, decoded in `control.v`, has its own testbench vector. Legend: ✅ done · ⬜ not done.

| Instruction | Type | Datapath | Control | Testbench |
|---|---|---|---|---|
| `add`   | R | ✅ | ✅ | ✅ |
| `sub`   | R | ✅ | ✅ | ✅ |
| `and`   | R | ✅ | ✅ | ✅ |
| `or`    | R | ✅ | ✅ | ✅ |
| `xor`   | R | ✅ | ✅ | ✅ |
| `sll`   | R | ✅ | ✅ | ✅ |
| `srl`   | R | ✅ | ✅ | ✅ |
| `sra`   | R | ✅ | ✅ | ✅ |
| `slt`   | R | ✅ | ✅ | ✅ |
| `sltu`  | R | ✅ | ✅ | ✅ |
| `addi`  | I | ✅ | ✅ | ✅ |
| `andi`  | I | ✅ | ✅ | ✅ |
| `ori`   | I | ✅ | ✅ | ✅ |
| `xori`  | I | ✅ | ✅ | ✅ |
| `slli`  | I | ✅ | ✅ | ✅ |
| `srli`  | I | ✅ | ✅ | ✅ |
| `srai`  | I | ✅ | ✅ | ✅ |
| `slti`  | I | ✅ | ✅ | ✅ |
| `sltiu` | I | ✅ | ✅ | ✅ |
| `lw`    | Load | ✅ | ✅ | ✅ |
| `sw`    | Store | ✅ | ✅ | ✅ |
| `beq`   | Branch | ✅ | ✅ | ✅ |
| `bne`   | Branch | ✅ | ✅ | ✅ |
| `blt`   | Branch | ✅ | ✅ | ✅ |
| `bge`   | Branch | ✅ | ✅ | ✅ |
| `bltu`  | Branch | ✅ | ✅ | ✅ |
| `bgeu`  | Branch | ✅ | ✅ | ✅ |
| `jal`   | Jump | ✅ | ✅ | ✅ |
| `jalr`  | Jump | ✅ | ✅ | ✅ |
| `lui`   | Upper-imm | ✅ | ✅ | ✅ |
| `auipc` | Upper-imm | ✅ | ✅ | ✅ |

Every instruction now runs through `riscv_top` and gets checked, not just decoded in isolation — `t01`-`t08` under `programs/` plus `tb_top.v` between them touch all 31.

**Per-file** — is the whole block implemented, does it have its own passing testbench:

| File | RTL | Testbench |
|---|---|---|
| `rtl/alu.v` | ✅ | ✅ |
| `rtl/control.v` | ✅ | ✅ |
| `rtl/regfile.v` | ✅ | ✅ |
| `rtl/imm_gen.v` | ✅ | ✅ |
| `rtl/imem.v` | ✅ | ✅ |
| `rtl/dmem.v` | ✅ | ✅ |
| `rtl/riscv_top.v` | ✅ | ✅ |

---

## 3. Architecture

- Single-cycle: one instruction, start to finish, per clock — no pipeline
- Combinational: IMEM, regfile reads, ALU, DMEM read
- Synchronous: regfile writes, DMEM writes, PC — all on `posedge clk`
- Harvard memory (separate IMEM/DMEM), both BRAM-backed, single-cycle access, word-addressed internally / byte-addressed externally
- IMEM: read-only, `$readmemh`-loaded. DMEM: read/write, zero-initialized.

**Address map:** `0x0000_0000–0x0000_FFFF` IMEM (64KB) · `0x1000_0000–0x1000_FFFF` DMEM (64KB) · `0x2000_0000–0x2000_000F` MMIO (reserved for Basys 3 LEDs/switches)

**Reset:** PC → 0 on sync active-high reset. Regfile and DMEM are *not* reset — whatever's there is there.

**Datapath:** hand-drawn, `docs/datapath.pdf`. Missing a few instructions that my cpu supports. **I will redraw it better w/ all instructions**

**Key wires:**

| Wire | Width | Description |
|---|---|---|
| `pc` | 32 | Current program counter |
| `pc_next` | 32 | Next PC (mux: PC+4, branch target, pc+imm, or rd1+imm) |
| `pc_plus4` | 32 | PC + 4 |
| `instr` | 32 | Current instruction from IMEM |
| `rs1_addr`, `rs2_addr` | 5 | Regfile read addresses |
| `rd_addr` | 5 | Regfile write address |
| `rs1_data`, `rs2_data` | 32 | Regfile read data |
| `imm` | 32 | Sign-extended immediate |
| `alu_a`, `alu_b` | 32 | ALU operands |
| `alu_result` | 32 | ALU output |
| `alu_zero` | 1 | ALU zero flag |
| `mem_addr` | 32 | DMEM address (usually `alu_result`) |
| `mem_wdata` | 32 | DMEM write data (`rs2_data`) |
| `mem_rdata` | 32 | DMEM read data |
| `result` | 32 | Regfile writeback value (mux: alu_result, mem_rdata, pc_plus4) |

---

## 4. Blocks

**ALU — `rtl/alu.v`** — ✅ done

```verilog
module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_op,
    output [31:0] result,
    output        zero          // 1 when result == 0
);
```

| `alu_op` | Op | | `alu_op` | Op |
|---|---|---|---|---|
| 0000 | ADD (a+b) | | 0101 | SRL (a>>b[4:0]) |
| 1000 | SUB (a-b) | | 1101 | SRA (a>>>b[4:0]) |
| 0001 | SLL (a<<b[4:0]) | | 0110 | OR |
| 0010 | SLT (signed a<b) | | 0111 | AND |
| 0011 | SLTU (unsigned a<b) | | 1010 | PASS (b, ignores a — used by `lui`) |
| 0100 | XOR | | | |

- `alu_op = {funct7[5], funct3}` — RISC-V's own funct3 encoding already lines up with this, so no per-instruction lookup table needed in the control unit
- `$signed()` for SLT/SRA, `b[4:0]` masks every shift amount so a runaway shift can't happen
- `zero` is combinational, `result == 32'b0`

**Register File — `rtl/regfile.v`** — ✅ done

```verilog
module regfile (
    input         clk,
    input         we,
    input  [4:0]  rs1_addr, rs2_addr, rd_addr,
    input  [31:0] rd_data,
    output [31:0] rs1_data, rs2_data
);
```

- Async read, sync write on `posedge clk` when `we` is high
- `x0` forced to 0 on the *read* side with a mux, not by blocking writes to storage (tried that first, doesn't work — a `reg` array word can't be both continuously assigned and procedurally written)

**Instruction Memory — `rtl/imem.v`** — ✅ done

```verilog
module imem (
    input [31:0] addr,
    output [31:0] instr
);
```

- Async lookup, word-aligned, `addr[15:2]` as the index
- Preloads with 'readmemh' — errors out until an actual `program.mem` exists
- Convert to sync-read BRAM once the pipeline phase starts

**Data Memory — `rtl/dmem.v`** — ✅ done

```verilog
module dmem (
    input clk,
    input we,
    input [31:0] addr,
    input [31:0] wdata,
    output [31:0] rdata
);
```

- Sync write / async read, word-only

**Immediate Generator — `rtl/imm_gen.v`** — ✅ done

```verilog
module imm_gen (
    input [31:0] instr,
    input [2:0] imm_src,
    output reg [31:0] imm
);
```

| `imm_src` | Format | Bit layout |
|---|---|---|
| 000 | I-type | `{{20{instr[31]}}, instr[31:20]}` |
| 001 | S-type | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| 010 | B-type | `{{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` |
| 011 | U-type | `{instr[31:12], 12'b0}` |
| 100 | J-type | `{{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` |

- Branch/jump immediates have an implicit 0 in bit 0 (instructions are 4-byte aligned)
- Most bug-prone module in the whole design — test every format against the ref sheet before wiring it up

**Control Unit — `rtl/control.v`** — ✅ done

```verilog
module control (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input        alu_zero,
    output       reg_write,
    output       mem_write,
    output [1:0] result_src,     // 00=ALU, 01=MEM, 10=PC+4
    output       alu_src_a,      // 0=rs1, 1=pc (AUIPC)
    output       alu_src_b,      // 0=rs2, 1=imm
    output [3:0] alu_op,
    output [2:0] imm_src,
    output [1:0] pc_src          // 0=pc+4, 1=branch, 2=jal, 3=jalr
);
```

| Instruction | `reg_write` | `mem_write` | `result_src` | `alu_src_a` | `alu_src_b` | `alu_op` | `imm_src` | `pc_src` |
|---|---|---|---|---|---|---|---|---|
| `add`   | 1 | 0 | ALU  | rs1 | rs2 | ADD  | – | pc+4 |
| `sub`   | 1 | 0 | ALU  | rs1 | rs2 | SUB  | – | pc+4 |
| `and`   | 1 | 0 | ALU  | rs1 | rs2 | AND  | – | pc+4 |
| `or`    | 1 | 0 | ALU  | rs1 | rs2 | OR   | – | pc+4 |
| `xor`   | 1 | 0 | ALU  | rs1 | rs2 | XOR  | – | pc+4 |
| `sll`   | 1 | 0 | ALU  | rs1 | rs2 | SLL  | – | pc+4 |
| `srl`   | 1 | 0 | ALU  | rs1 | rs2 | SRL  | – | pc+4 |
| `sra`   | 1 | 0 | ALU  | rs1 | rs2 | SRA  | – | pc+4 |
| `slt`   | 1 | 0 | ALU  | rs1 | rs2 | SLT  | – | pc+4 |
| `sltu`  | 1 | 0 | ALU  | rs1 | rs2 | SLTU | – | pc+4 |
| `addi`  | 1 | 0 | ALU  | rs1 | imm | ADD  | I | pc+4 |
| `andi`  | 1 | 0 | ALU  | rs1 | imm | AND  | I | pc+4 |
| `ori`   | 1 | 0 | ALU  | rs1 | imm | OR   | I | pc+4 |
| `xori`  | 1 | 0 | ALU  | rs1 | imm | XOR  | I | pc+4 |
| `slli`  | 1 | 0 | ALU  | rs1 | imm | SLL  | I | pc+4 |
| `srli`  | 1 | 0 | ALU  | rs1 | imm | SRL  | I | pc+4 |
| `srai`  | 1 | 0 | ALU  | rs1 | imm | SRA  | I | pc+4 |
| `slti`  | 1 | 0 | ALU  | rs1 | imm | SLT  | I | pc+4 |
| `sltiu` | 1 | 0 | ALU  | rs1 | imm | SLTU | I | pc+4 |
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
| `lui`   | 1 | 0 | ALU  | –   | imm | PASS | U | pc+4 |
| `auipc` | 1 | 0 | ALU  | pc | imm | ADD | U | pc+4 |

- `alu_op` isn't a per-row lookup for R-type/I-type rows — it's generated from `{funct7[5], funct3}` directly (see 4.1). Real decode logic is only needed for the rows where it isn't derived that way: `lw`/`sw`/`jalr`/`auipc` (always ADD) and branches (SUB/SLT/SLTU off branch `funct3`)
- The "–" rows don't write a register, so `result_src` is a don't-care there
- Watch out for: `funct7[5]` only means something real for R-type and I-type-shift (`slli`/`srli`/`srai`) — every other OP-IMM instruction has to force that bit to 0, since it's just part of the immediate for those, not a real subtract/negate flag. Learned this one the hard way (`andi` with certain immediates was silently landing on the wrong ALU op before this got fixed).

**Top Module — `rtl/riscv_top.v`** — ✅ done

```verilog
module riscv_top (
    input clk,
    input rst,
    output [31:0] debug_pc,
    output [31:0] debug_instr
);
```

- PC register (sync reset), PC+4 adder, next-PC mux, dedicated `pc+imm` adder shared by branch-target and `jal`, all block instantiations, writeback mux
- `jalr`'s target reuses `alu_result` instead of a second adder — `control.v` already sets `alu_src_a=rs1, alu_src_b=imm, alu_op=ADD` for `jalr`, so the ALU's already computing `rs1+imm`. Bit 0 gets cleared in the `pc_next` mux itself.
- Smoke-tested end to end with a hand-assembled program covering arithmetic, load/store, both branch directions, `lui`, `auipc`, `jal`, and `jalr` — all correct together, not just per-block

---

## 5. Verification

**Per-block:**

| Block | Test cases |
|---|---|
| ALU | Every op, signed/unsigned edge cases, shift-amount masking, zero flag, undefined opcode |
| Regfile | Write/read across ports, `x0` behavior, `we=0` no-op, read-during-write to the same address |
| Control | Every opcode against the Section 4 table |
| Imem | Known pattern preloaded directly into the array, verify readback at several addresses |
| Dmem | Write/read across addresses, `we=0` no-op, zero-init, read-during-write to the same address |
| Imm_gen | One real instruction encoding per format (I/S/B/U/J) plus an undefined `imm_src`, checked against hand-computed values |

**Integration** (hand-assembled programs, `.mem` files under `programs/`):

1. `t01_addi.mem` — basic arithmetic
2. `t02_load_store.mem` — store then load into a different register
3. `t03_branch.mem` — countdown loop with `bne`, plus all 6 branch conditions (`beq`/`bne`/`blt`/`bge`/`bltu`/`bgeu`)
4. `t04_jump.mem` — `jal`, verify return address
5. `t05_sum_array.mem` — sum 10 numbers in memory
6. `t06_all_r_type.mem` / `t07_all_i_type.mem` — exercise every R/I-type
7. `t08_lui_auipc.mem` — upper-immediate ops

Try to run a subset of the official `riscv-tests` suite once v1 works.

---

## 6. Notes

**Open questions:**
- When it's time to pipeline: rewrite from scratch rather than refactor — cleaner than bolting pipeline registers onto something that wasn't built for it

**Rough timeline**:

| Week | Milestone |
|---|---|
| 1 | ALU + regfile + control done and tested *(here)* |
| 2 | Imm_gen + imem/dmem block-tested, `riscv_top.v` wired |
| 3 | t01–t04 pass in sim |
| 4 | t05–t08 pass; start pipeline design |
| 5+ | Pipeline datapath, then hazards |

**References:**
- Harris & Harris, *Digital Design and Computer Architecture: RISC-V Edition*, Ch. 7 — main reference, basically my bible right now
- RISC-V Instruction Set Manual, Volume I (Unprivileged)
- darkriscv (github.com/darklife/darkriscv), picorv32 (github.com/YosysHQ/picorv32)

---

## 7. Later: Pipelining + What's In Between

Not building this yet, just leaving notes.

**Between single-cycle working and starting the pipeline:** byte/halfword loads and stores (`lb`/`lh`/`lbu`/`lhu`/`sb`/`sh`), trap instructions (`fence`/`ecall`/`ebreak`), maybe adopt SystemVerilog if it's not too disruptive, Basys 3.

**Pipeline skeleton:** IF → ID → EX → MEM → WB.
- Data hazards: EX/MEM → EX and MEM/WB → EX forwarding, load-use stall
- Control hazards: predict-not-taken, flush IF/ID + ID/EX on a taken branch
- Structural: none expected (Harvard memory)
- Pipeline register contents and the forwarding/hazard-detection units are TBD — design those after the plain 5-stage datapath works with no hazard handling at all
