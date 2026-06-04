# kbee-05 — precision-backoff playbook

**Status:** **archived / not active for current kbee-04 branch**.

This document is retained as a historical fallback playbook. The specific
failure modes that originally activated it (early kbee-03 / kbee-04 timing and
mixed-trajectory instability) were addressed by topology and timing alignment
work in later redesign exports, and current complement-pair checks
(`NOR+OR`, `NAND+AND`, `XOR+XNOR`) are passing in the active flow.

**When to use this doc:** only if a future hardware or timing regression brings
back a sustained precision breakdown that is not resolved by the current
clock/phase/load-alignment conventions.

*"plan §N" citations refer to the project's internal design plan, which is not included in this public repo.*

## 0. kbee-03-specific finding — topology fix, VALIDATED 2026-04-24

**Status:** applied and validated on d2-mid. The kbee-03 `.ad2` now
has the 7-CAM topology with `z_delay` in CAB 4.

The original kbee-03 design's SumDiff saw `z[n]` on Input 1 but
`classifier(z[n−1])` on Inputs 2 and 3, because of the 1-clock delay
through the GainSwitch gain stage (see `docs/ad2-conventions.md` §8). This
asymmetric delay turned the middle-branch fixed point `z* = 0.5 V`
into an unstable period-2 orbit that destroyed any CSV row whose ideal
trajectory *transitioned into* the middle branch (e.g. d2-mid, digits
`21111111`).

**Fix:** insert a plain `Hold` CAM on the `z_hold.Out → residue.Input 1` branch, making *both* the `+3·z` term and the classifier-correction
terms reference `z[n−1]`:

```
residue[n] = 3·z[n−1] − a(z[n−1])·V − b(z[n−1])·V
           = 3·(z[n−1] − d_{n−1}·V/3)
```

**Key configuration detail** (missed on first attempt, see
`docs/ad2-conventions.md` §9): the new Hold's **Input Sampling Phase must be
Φ2** (opposite of `z_hold`'s Φ1), otherwise the two-Hold chain
collapses to a half-cycle delay and the fix doesn't actually do
anything. Concretely for kbee-03:

- `z_hold` (existing): Input Sampling Phase = Φ1
- `z_delay` (new, 7th CAM): Input Sampling Phase = **Φ2**

**Result:** d2-mid now passes cleanly. `z_hold.Out` trace at
`Z_sum = 0.833257 V`:

| Before fix (failing): | 0.833, 0.500, **−0.501**, 0.499, −2.502, 1.498, −3.000, 3.000 |
| After fix (passing): | 0.833, 0.500, 0.500, 0.500, 0.499, 0.499, 0.499, 0.498 |

The middle-branch fixed point is now stable; d2-mid shares the same
slow-drift signature (0.500 → 0.498 over 6 ticks) that d1-mid had
before the fix.

**CAB budget:** the `.ad2` file easily fit a 7th CAM. CAB 4 went from
2 CAMs to 3 (`gs_load`, `z_hold`, `z_delay`). Layout is still within
the 4-CAB budget for AN231E04.

**Remaining levers below** (A/B/C/D) apply to the *DAC-edge* failure
mode (d2-lo), which is independent of the iteration-instability fix
and therefore unaffected by `z_delay`.

## 1. Capture the breakdown point

From `data/kbee-04-full-hw.csv`:

1. Run the existing mismatch analysis (reuse
   scope captures against `data/kbee-w8-refs.csv`, or a
   per-digit split of `A_{NOR,XOR,AND}` against the CSV references).
1. For each digit position `k = 0..7`, compute the fraction of the
   65536 test vectors whose output `digit_k` (decoded from the measured
   `A_*_V`) differs from the reference's `digit_k`.
1. Find `k*` = first position where mismatch rate > 5 %.
1. Record to `fpaa/docs/kbee-05-breakdown-<date>.md`:
   - `k*` (the ceiling digit)
   - the failure rate histogram for positions `k* .. 7`
   - whether failures cluster near threshold boundaries (z_code near
     2187 or 4374) — clustering there says "comparator offset";
     uniform distribution across z says "accumulator gain error".

This data drives which lever to try next.

## 2. Lever A — stretch V_range via differential swing

Motivation (plan §5): at `V_range = 1.000 V` single-ended, `V_unit ≈ 0.15 mV`, below typical SC noise on AN231E04. Differential swing gives
roughly 4× voltage headroom.

### Changes

- Chip Settings: enable differential signal mode on all input, residue,
  and output pads.
- Signal ground becomes the midpoint of a ±2 V differential pair, so
  `V_range` is redefined as the **differential span 4.000 V**, i.e. −2 V
  to +2 V. `V_unit = 4.000 V / 6561 ≈ 0.610 mV`, a ~4× relaxation.
- Update `data/kbee-w8-refs.csv` voltage columns: multiply every
  `*_V` column by 4 (and shift the baseline if the CSV consumer wants
  single-ended-equivalent voltages). Alternatively, rename the columns
  `*_V_diff` and keep the originals for single-ended designs.
- Update siggen test inputs to drive differential: `x+` and `x-` pins
  swinging in opposite directions around signal ground.
- Update AD2 layout: every CAM that was single-ended in kbee-03 / -04
  needs its input/output mode flipped to differential. This is a
  design-file edit, not a wiring change — but it does mean saving under
  a new filename, `fpaa/designs/kbee-04-diff.ad2`, to avoid clobbering
  the single-ended baseline.

### Rerun & recompare

Rerun the full sweep and recompute `k*`. Target: `k* = 8` (i.e. no
breakdown up to and including the LSB).

## 3. Lever B — chopping & calibration sweep

If Lever A gains headroom but `k*` still ≤ 6:

1. **Chopper-stabilised variants.** For each of the two comparators and
   the residue SumDiff, use the `_chop` variant of the CAM if AD2
   offers one. Chopper stabilisation shifts low-frequency offsets to
   the chop frequency and filters them out, killing systematic offset
   at the cost of a few % bandwidth.
1. **Threshold calibration.** Apply a Phase-3-style ramp calibration to
   learn the real `V_range/3` and `2·V_range/3` thresholds as seen by
   the comparators:
   - Sweep `z` from 0 to `V_range` at a slow ramp rate (≥ 100 µs full
     span, so the SC feedback has time to settle).
   - Capture `D_oneOrTwo` and `D_isTwo` on the scope.
   - Record the actual `z_V` at which each comparator flips. Those are
     the **effective thresholds** — write them back into the AD2
     comparator CAMs as corrected reference voltages.
1. **Accumulator V_unit calibration.** Apply a single-digit test where
   exactly one accumulator should receive exactly one tick's V_unit
   at a known position. Compare the measured `A_V` against
   `V_unit · 3^{7−k}`. Adjust the `V_unit` Voltage-CAM reference until
   the measured value lands within 0.5 LSB of the reference.

Rerun the full sweep. Target: `k* = 8`.

## 4. Lever C — larger V_range only on residue path

If Levers A and B together still fall short, try giving the residue
path a wider voltage budget than the output accumulators. The residue
path is the one that sees 3^8 = 6561× gain compounding; the
accumulators see at most 3^7 = 2187×.

1. In `fpaa/designs/kbee-04-diff.ad2`, change the residue-path SumDiff
   to use a custom reference of `2·V_range` (= 8 V differential span)
   while keeping the accumulator path at `V_range`.
1. Insert a divide-by-2 gain stage on the comparator inputs so they
   still fire at the correct relative thresholds.
1. This is expensive in CAB count (+ 1 gain stage) — only pursue if
   the breakdown analysis from step 1 points to the residue path
   specifically (uniform failures across all digits) rather than the
   accumulators (failures clustered in the last 1-2 digits).

Rerun. Target: `k* = 8`.

## 5. Lever D — measured noise model + test-vector pruning

If none of A/B/C gets `k* = 8`, switch to a probabilistic framing:
the design is "correct on 95 % of inputs" at W = 8 rather than
"correct on all inputs at some lower W". For RISC-V use this is
unacceptable (one bad bit in one in twenty 32-bit ops is a hardware
bug), but it can still be a publishable analogue-compute result.

Record this state as `kbee-04-prob` and move on to Lever E only if the
RISC-V goal remains the priority.

## 6. Lever E (last resort) — reduce W

If all of the above fail:

1. Rebuild kbee at `W = 5` (say): regenerate the reference CSV
   (`python3 scripts/gen-kbee-refs.py` with `W = 5` set at the top; from repo root),
   and re-layout the AD2 design with the narrower encoding. Most of
   the CAB layout is W-agnostic — only the comparator thresholds and
   the `V_unit` reference change.
1. Document the variant at `docs/kbee-04-w5.md` as an explicit
   precision-limited fallback. Not the prototype target.
1. The 32-bit RISC-V path (plan §9) widens correspondingly: at
   `W = 5` we need `ceil(32 / 5) = 7` kbee instances per 32-bit op,
   with a bit-boundary re-slicing layer at the operand ingress and
   egress. The analog-analog chaining guarantee still holds.

## Decision tree (TL;DR)

```
kbee-04 hw sweep:
  breakdown digit k* = 8  ──► ship kbee-04, run kbee-06 NAND compose
  k* = 6 or 7             ──► Lever A (diff swing)
  still k* ≤ 6            ──► Lever B (chopping + cal)
  still k* ≤ 6            ──► Lever C (widened residue path)
  still k* ≤ 6            ──► Lever D (probabilistic variant) OR
                              Lever E (W = 5 fallback)
```

## Tooling

Create `scripts/kbee-breakdown.py` at backoff-time (no need to ship it
before we know the axes of the failure). It reads
`data/kbee-04-full-hw.csv`, computes per-digit error rate and per-input
error clustering, and emits the breakdown Markdown into
`fpaa/docs/kbee-05-breakdown-<date>.md`. Avoids hand-eye pattern-matching on
oscilloscope traces.
