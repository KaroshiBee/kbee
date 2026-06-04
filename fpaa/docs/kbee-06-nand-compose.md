# kbee-06 — NAND composition (4 kbee instances, analog-analog chain)

**Design file:** `fpaa/designs/kbee-06-nand.ad2` (authored in AD2 from scratch).
**Target chip:** AN231E04; at sim time a single chip with four kbee instances
in series (if four kbee-04 instances fit into one design simulation);
at hardware time, two chips with output-to-input wire (see "shapes" below).
**Depends on:** kbee-04 passing. Verify against `python/kbee.py` and
`data/kbee-w8-refs.csv` to compare against a pure-Python NAND oracle.

*"plan §N" citations refer to the project's internal design plan, which is not included in this public repo.*

## Goal

Prove the headline claim of the kbee design: **analog outputs feed back as
analog inputs with no binary/ternary conversion at the boundary**, using
NOR's universality (NAND from NOR) as the proof case.

The composition is lifted verbatim from the NAND-from-NOR block in
[`python/test/test_kbee.py`](../../python/test/test_kbee.py):

```python
# NOR is universal - can make a NAND gate
# [ ( A NOR A ) NOR ( B NOR B ) ] NOR
# [ ( A NOR A ) NOR ( B NOR B ) ]
nNORn,    _ = g.norandxor(n, n)["nor"]           # kbee call #1
mNORm,    _ = g.norandxor(m, m)["nor"]           # kbee call #2
nnNORmm,  _ = g.norandxor(nNORn, mNORm)["nor"]   # kbee call #3
_, z1NANDz2 = g.norandxor(nnNORmm, nnNORmm)["nor"]  # kbee call #4
```

Mapping one-to-one onto hardware:

| kbee call | inputs `(x, y)` | output consumed |
|-----------|-----------------|-----------------|
| K1 | `(n, n)` | `A_NOR` → `nNORn` |
| K2 | `(m, m)` | `A_NOR` → `mNORm` |
| K3 | `(nNORn, mNORm)`| `A_NOR` → `nnNORmm` |
| K4 | `(nnNORmm, nnNORmm)` | `A_NOR` → `NAND(n,m)` |

The XOR and AND outputs of the four kbee instances are unused for this
specific composition but should still be captured as a sanity plot.

## Shape (a) — AD2 sim, four kbee instances in one design

- Copy the kbee-04 CAM subcircuit into a reusable sub-schematic
  (in AD2 this is a "macro") and instantiate it four times on the same
  chip sheet. AN231E04 has only 4 CABs, so four full kbee-04s do *not*
  fit. **Sim-only**: AD2's simulator ignores the CAB count cap — it
  will happily simulate an arbitrary number of copies of the design's
  math for verification.
- Wire K1's and K2's `A_NOR` outputs into K3's inputs; K3's `A_NOR`
  output into both of K4's inputs; K4's `A_NOR` output is the final
  NAND result.
- This sim-first shape is the plan's stated starting point (plan §0
  "working conventions"), allowing us to prove analog-analog chaining
  numerically before committing to hardware plumbing.

## Shape (b) — single-chip time-multiplexed (hardware)

One physical AN231E04 loaded with kbee-04, driven through the
composition by the dev-board MCU:

1. Preload `n` and `m` on ADC/DAC-backed input pads.
1. MCU runs four operations in sequence:
   - Op1: drive `(x, y) = (n, n)` → read `A_NOR` → store in MCU RAM as
     `V_nNORn` (float volts, no quantisation).
   - Op2: drive `(x, y) = (m, m)` → read `A_NOR` → `V_mNORm`.
   - Op3: drive `(x, y) = (V_nNORn, V_mNORm)` → read `A_NOR` →
     `V_nnNORmm`.
   - Op4: drive `(x, y) = (V_nnNORmm, V_nnNORmm)` → read `A_NOR` →
     `V_NAND`.
1. Compare `V_NAND` to the NAND oracle voltage for `(n, m)`.

The key point: the MCU reads `A_NOR` as an **analog voltage** and writes
it back as an **analog voltage** to the next op's inputs. At no stage
do we re-digitise back to an 8-bit binary representation. The DAC/ADC
resolution on the dev board sets the practical precision floor for this
shape; log it explicitly.

## Shape (c) — two chips wired in series (hardware, flashiest)

Two AN231E04s, K1 and K2, both running kbee-04. K1's three output
pads feed K2's three input pads directly (K2 uses only two of K1's
outputs — `A_NOR` into both of its input cells for the "NOR-with-itself"
pattern). Execute the composition as:

- K1: input `(n, m)` (or staged via an intermediate op) →
- K2: input `K1(...)` → NAND result

Full four-deep chaining would want four chips; two chips suffice for
the proof-of-concept `NOR(NOR(a, a), NOR(b, b))` two-step composition.

Shape (c) is aspirational for the write-up; shape (b) is the plan's
explicit sub-choice for the hardware phase. Start with (a), then (b).

## Verification

Pure-software oracle: run `Gates2Inputs(8).norandxor` four times in
sequence on the integer codes, check that the final `nor_code` equals
`(~(n & m)) & 0xFF` reinterpreted as a base-3 {0,1} code. Also record
the intermediate codes so the AD2 sim / bench capture can be spot-checked
at every stage, not just the final output.

The script outputs `data/kbee-06-nand-oracle.csv` with one row per
`(n_bin, m_bin)` pair (again 65536 rows) and columns:

```
n_bin, m_bin,
n_code, m_code,
nNORn_code, mNORm_code, nnNORmm_code, NAND_code,
nNORn_V,   mNORm_V,   nnNORmm_V,   NAND_V,
expected_NAND_bin
```

Pass criterion (software): `NAND_code` round-trips to the expected
binary NAND for all 65536 rows. Pass criterion (AD2 sim): AD2's measured
`V_NAND` matches `NAND_V` within the kbee-04 sim tolerance (effectively
0, since AD2 sim is ideal-analog). Pass criterion (hardware): mismatch
rate ≤ 10 % (double the kbee-04 bar, because four kbee ops stack their
errors — expected due to error compounding even if each individual op
sits at 5 %).

## Build steps (AD2 sim, shape (a))

1. Open `fpaa/designs/kbee-04.ad2` in AD2. Copy the CAMs except the
   I/O cells into a named sub-schematic `kbee_core`.
1. In a new design `fpaa/designs/kbee-06-nand.ad2`, drop four
   instances of `kbee_core`.
1. Wire:
   - `n` input pad → K1.x, K1.y, K2.x, K2.y (no, that's wrong — K2
     takes `m`, not `n`). Actually:
     - K1.x = K1.y = `n`
     - K2.x = K2.y = `m`
     - K3.x = K1.A_NOR, K3.y = K2.A_NOR
     - K4.x = K4.y = K3.A_NOR
     - `NAND_out` = K4.A_NOR
1. Drive `n` and `m` with siggens set to the test row's `n_V`/`m_V`
   (where `n_V = n_code / 6561` just like kbee's `x_V`).
1. `F5` for ≥ 150 µs (4 × 32 µs per kbee op + pipeline startup).
1. Read `NAND_out` at the last `VALID` edge; log to
   `data/kbee-06-nand-sim.csv`.

## Pass criteria

- **Sim:** zero mismatches across the 65536-row sweep.
- **Hardware (shape b):** ≤ 10 % mismatch rate across the sweep, with a
  breakdown histogram per intermediate stage. If mismatch rate blows up
  at stage 3 specifically, it points at the `(nNORn, mNORm)` input
  being out-of-spec (values larger than kbee's binary-constrained input
  assumption) — a real risk since `nNORn` and `mNORm` are themselves
  binary-constrained ternary codes produced analogly.

## Known risks

- **Input constraint preservation.** kbee assumes input digits are in
  `{0, 1}`. The output of kbee is also in `{0, 1}`, *by construction of
  the math*. On real silicon a noisy output may sit slightly above 0
  or below the quantised `1` voltage; the next kbee interprets that as
  a "digit-close-to-0-or-1" which the comparators still classify
  correctly so long as the noise stays below `V_range / 6 ≈ 0.17 V`
  per-digit (half of a tick-0 threshold). This is the analogue
  equivalent of "noise margin", and is an implicit feature of the
  V_range = 1 V encoding.
- **Settling time between ops.** Each kbee takes 32 µs. Between ops,
  the MCU must hold previous inputs stable long enough for the output
  to settle, then latch the output before switching to the next
  operation's inputs. Allow ~10 µs of margin each way, so each NAND
  composition takes ~4 × (32 + 20) ≈ 208 µs.

## Handoff

Once shape (a) passes, we've formally proved analog-analog chaining
works for the canonical universal-gate composition. kbee-07 (the
RISC-V sketch) is then a paper exercise over the same primitive.
