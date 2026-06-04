# KBee Lean 4 proofs

Machine-checked verification of the generic base-N, N−1-input algorithm from
`docs/base-n-nminus1-algorithm.md`.

## Build

From the repo root (Nix):

```bash
cd proofs && nix develop -c lake build Kbee
```

## What is proved

- Carry-free column sum and input bounds (`Helpers.lean`)
- MSB-first residue extraction (`Residue.lean`)
- Gate accumulators linked to extracted digits (`Gates.lean`)
- End-to-end `nor/and/xor/xnor_algorithm` theorems (`Algorithm.lean`)
- Doc-aligned worked examples, N=3 and N=4, W=8 (`Examples.lean`)

## Out of scope (for now)

These proofs are **atemporal at the hardware level**: they reason about tick index `t` as
natural-number recursion, not about clocks, phases, or analog settling.

Not covered:

- FPAA CAM pipeline delays (Hold chains, GainSwitch control lag)
- Load/strobe sequencing and kbee-04 sub-tick timing
- Feedback-loop convergence (e.g. kbee-03 fixed points)
- Multi-cell chaining handshakes

## Likely next verification step

**Controller / timing proofs** — showing that a concrete state machine implements the abstract
W-tick operational loop (doc §4.1). Good tool fits:

- **TLA+** — model the MCU/FPAA controller, check safety and refinement with TLC or TLAPS.
- **Veil** — Lean 4 transition-system framework ([verse-lab/veil](https://github.com/verse-lab/veil/));
  stays in the same proof ecosystem, supports model checking and interactive proof.

The integer algorithm is already settled here; temporal or transition-system work targets
**physical realisation**, not digit arithmetic.
