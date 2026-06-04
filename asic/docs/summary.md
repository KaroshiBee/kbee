# KBee ASIC Summary (Base-4, Amperage Domain)

## Executive Summary

This document defines the current architecture target for the KBee ASIC cell:

- **Domain:** current-mode (amperage-domain) logic
- **Numeric format:** **4-digit base-4** (`256` legal levels per lane)
- **Cell shape:** multi-input (`A`, `B`, `C`), **single muxed analog output**
- **Selector control:** `ui_in[3:0]` chooses one of 16 operating modes
- **Unit step:** `50 nA`
- **Full-scale output:** `12.75 uA`

The design goal is a compact polymorphic logic primitive that chains directly in the current domain and maps cleanly to a Tiny Tapeout `2x2` mixed-signal implementation path.

## 1) Core Architecture

The KBee cell is a polymorphic current-steering logic macro.

- Inputs and outputs are represented as current magnitudes.
- A 4-bit digital selector configures function at runtime.
- One physical cell implements multiple Boolean and utility behaviors.
- Cell outputs can drive downstream KBee inputs directly (no internal ADC/DAC boundary required between cells).

### Intended benefits

- Higher wiring efficiency via multi-level current encoding.
- Reusable transistor fabric across many logic roles.
- Unified primitive for combinational datapath and control support.

## 2) Canonical Numeric Encoding

### Base constants

- `I_step = 50 nA`
- Digits: `d0, d1, d2, d3 in {0, 1, 2, 3}`
- Positional weights: `[1, 4, 16, 64]`

### Current mapping

`I_out = 50 nA * (d0 + 4*d1 + 16*d2 + 64*d3)`

### Range table

| Quantity | Value |
|---|---|
| Minimum code | `0000_4` |
| Maximum code | `3333_4` |
| Decimal code range | `0..255` |
| Current range | `0..12.75 uA` |
| Number of legal levels | `256` |

### Operand-format constraint (binary-format base-4)

Datapath operands use base-4 lanes with restricted digits:

- `A` and `B` are 4-digit base-4 values with digits in `{0, 1}` only ("binary format").
- `C` is normally provided as a base-4 lane, but `C = 2222_4` is a reserved sentinel indicating 2-input mode.
- In 2-input mode (`C = 2222_4`), internal masking behavior is enabled for logic-family opcodes.

## 3) I/O Definition

| Pin | Direction | Meaning |
|---|---|---|
| `ua[0]` | In | Input vector A (4-digit base-4, digits restricted to `0/1`) |
| `ua[1]` | In | Input vector B (4-digit base-4, digits restricted to `0/1`) |
| `ua[2]` | In | Input vector C (base-4 control lane; `2222_4` sentinel enables 2-input masking mode) |
| `ua[3]` | Out | Single multiplexed analog output lane |
| `ui_in[3:0]` | In | Digital mode select |
| `rst_n` | In | Global hardware reset |

## 4) Selector Truth Table (Finalized for This Revision)

### Input C auto-mask policy

For logic opcodes (`0000..0101`), when `C = 2222_4` (2-input mode), `Input C` triggers auto-mask behavior:

- `AND`, `NAND`: internal mask path uses logical all-ones when mask mode is active.
- `NOR`, `OR`, `XOR`, `XNOR`: internal mask path uses logical all-zeros when mask mode is active.

For unary and pass-through opcodes (`0110..1011`), `Input C` is consumed only by opcodes that explicitly target `C`.

### Error conditions

- `C = 2222_4` is reserved as a 2-input sentinel for logic-family opcodes (`0000..0101`) only.
- If `ui_in = 1000` (`NOT(C)`) and `C = 2222_4`, the operation is an **invalid operand mode** error.

### 16-mode map

| `ui_in[3:0]` | Mode | Output behavior on `ua[3]` |
|---|---|---|
| `0000` | Base-4 AND | `Y = AND(A, B)` with AND-family auto-mask policy |
| `0001` | Base-4 NAND | `Y = NAND(A, B)` with AND-family auto-mask policy |
| `0010` | Base-4 NOR | `Y = NOR(A, B)` with OR-family auto-mask policy |
| `0011` | Base-4 OR | `Y = OR(A, B)` with OR-family auto-mask policy |
| `0100` | Base-4 XOR | `Y = XOR(A, B)` with OR-family auto-mask policy |
| `0101` | Base-4 XNOR | `Y = XNOR(A, B)` with OR-family auto-mask policy |
| `0110` | NOT(Input 1) | `Y = NOT(A)` |
| `0111` | NOT(Input 2) | `Y = NOT(B)` |
| `1000` | NOT(Input 3) | `Y = NOT(C)` |
| `1001` | Pass-through(Input 1) | `Y = A` |
| `1010` | Pass-through(Input 2) | `Y = B` |
| `1011` | Pass-through(Input 3) | `Y = C` |
| `1100` | Constant zero | `Y = 0 uA` |
| `1101` | Constant unit step | `Y = 50 nA` |
| `1110` | Constant full scale | `Y = 12.75 uA` |
| `1111` | Clear internal state | Clears internal analog/storage state, then resumes normal operation on next selected mode |

## 5) RV32I System Integration Notes

The broader architecture concept remains:

- deterministic synchronous control path,
- dedicated `+1` program-counter increment block,
- word-addressed internal PC representation with external byte-address compatibility,
- boundary conversion for standard off-chip digital memory interfaces.

These are RV32I system-level goals and require separate microarchitecture and timing closure documents.

## 6) RV32I Area and Fit Estimate (Tiny Tapeout `2x2`)

Tile area reference: `64,000 um^2`

| Group | Estimate |
|---|---|
| KBee computational core | ~50% |
| Current-latch storage structures | ~18% |
| Routing / rails / overhead | ~22% |

Planning assumption: full design target can fit within an approximately 90% utilization envelope, pending schematic/layout extraction and signoff checks.

## 7) Implementation Path

1. Bench or FPAA validation of base-4 current arithmetic and mode transitions.
1. Open-source ASIC flow setup (`sky130`, simulation environment).
1. Xschem capture of KBee cell current mirrors, steering network, and selector paths.
1. Ngspice verification for DC levels, transient settling, chaining behavior, and PVT sensitivity.
1. Layout, extraction, and post-layout simulation before final integration.
