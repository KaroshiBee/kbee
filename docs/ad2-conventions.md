# AD2 and kbee conventions

Project-wide rules for FPAA bring-up, reference data, and AnadigmDesigner2
simulation. Algorithm spec: [`base-n-nminus1-algorithm.md`](base-n-nminus1-algorithm.md).

## Line endings

All tracked text files in this repo are **LF-only**. When authoring CSV from
Python, pass `lineterminator="\n"` to `csv.writer` (the module default is
`\r\n`):

```python
with open(path, "w", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
```

## Ternary encoding bounds

Always state bounds in base-3-code form first; voltage is a derived view.

- Inputs: `x, y ∈ [00000000_3, 11111111_3] = [0, 3280]` (digits `{0,1}`).
  In voltage: `0 .. 3280/6561 · V_range ≈ 0 .. 0.4999 V`.
- Sum: `z = x + y ∈ [00000000_3, 22222222_3] = [0, 6560]` (digits `{0,1,2}`;
  no inter-digit carry). In voltage: `0 .. V_range`.
- Accumulator outputs: `A_NOR, A_XOR, A_AND ∈ [00000000_3, 11111111_3]`
  with the invariant `A_NOR + A_XOR + A_AND = 3280 = (3^8 − 1)/2`.

Do not conflate the `[0, 3280]` input range with the `[0, 6560]` sum range.
When a doc or test picks hand-rolled `(x_bin, y_bin)` pairs, the leading base-3
digit `d_0 = digit_0(z)` is determined by `z < 2187` / `z < 4374` thresholds
and usually does **not** match the MSB of `x_bin | y_bin` directly — always
compute `z_code = x_code + y_code` first.

## Test picks come from the reference CSV

All test-row worksheets for kbee designs come from `data/kbee-w8-refs.csv`, not
from hand-rolled `(x_bin, y_bin)` tables in doc prose. Hand-rolled picks have a
track record of miscategorising `digit_0`. If a doc needs inline examples, use
only true-corner rows (`(0,0)`, `(255,255)`) or cite oracle rows verbatim.

## Ground-truth reference

The executable algorithm oracle lives at `python/kbee.py`. Generate test
vectors with `scripts/gen-kbee-refs.py` and emit into `data/kbee-w8-refs.csv`.
Property tests at W=4/16/32 are in `python/test/test_kbee.py`.

## AD2 design files

`.ad2` files are proprietary AnadigmDesigner2 binaries. Never attempt to read,
write, or diff them as text. Design deliverables are the Markdown build guides
in `fpaa/docs/`, not the `.ad2` files.

## CAM library reference

Before citing any CAM behaviour, consult a local knowledge base built from the
CHM help shipped with AD2 (not committed to this repo).

Set **`KBEE_KB`** to the root of that checkout — the directory that contains
`cam-docs/` (converted Markdown/HTML per CAM). Read docs at
`$KBEE_KB/cam-docs/`; build or refresh the KB with the converter scripts in the
same tree (outside this repo).

```bash
export KBEE_KB=/path/to/your/kbee-kb   # example; any location you choose
```

AN231E04-compatible CAMs live under `cam-docs/apex/` (paths in FPAA notes are
relative to `cam-docs/` unless a bucket prefix is given).

## AD2 patterns (locked in by kbee-00 sim, 2026-04-22)

These are the AD2-side conventions every kbee-0N design follows. They are
non-negotiable defaults; deviate only with an explicit reason captured in the
per-stage doc.

### 1. Hold-before-Bypass on every analog output pin

Half-cycle SC CAMs (`SumDiff`, `GainSwitch`, `Gain`, `Integrator`, etc.)
output a valid value on only one clock phase and reset toward signal ground on
the other. An `IOCell` configured as **Output Bypass** is a continuous-time
pin driver — feeding it a half-cycle output exports a square wave whose DC
average pins near 1.5 V regardless of the inputs.

Rule: between the last SC stage of any analog signal and its Output Bypass I/O
cell, insert one Apex `Hold` CAM, with **Input Sampling Phase set to match the
upstream CAM's Output Phase**. The Hold's output is continuous and drives the
IOCell cleanly.

Exemptions: outputs already terminated in a Hold-class CAM (`Hold`,
`HoldVoltageControlled`, `GainHold`, …) are safe to wire directly to the pin.

CAB-budget consequence: each analog output pin costs **one extra CAB** unless
an existing Hold can be reused.

### 2. Differential siggens for inputs

AN231E04 I/O cells are physically differential; AD2's simulator refuses to run
with `"In_neg not connected"` if a Single-ended siggen is wired to an input
pad. Default siggen recipe per input pin:

- Output: **Differential**
- Peak Amplitude: **0** (DC test rows; non-zero only for AC sims)
- **Differential Offset:** the logical operand voltage (e.g. `x_V` or `y_V`
  from the reference CSV) in volts
- **Common Mode Offset: 1.500 V** (signal ground on AN231E04)

### 3. Scope channel convention

Probe at chip pins (not internal nets). Standard four-channel assignment:

| Channel | Probe | Reads |
|---------|---------------------|----------------------------------------------------|
| Ch 1 | `x` input pin (pos) | `Differential Offset` of x's siggen = `x_V` |
| Ch 2 | `y` input pin (pos) | Same for y = `y_V` |
| Ch 3 | output pin (pos) | single-ended absolute = `1.5 V + V_logical / 2` |
| Ch 4 | output pin (neg) | single-ended absolute = `1.5 V − V_logical / 2` |

Decoded logical output: **`V_logical = Ch 3 − Ch 4`**.

### 4. Clock naming

Point SC CAMs at AD2's pre-defined slots (`Clock 2`, `Clock 3`, …) rather than
renaming chip clocks in Chip Settings. Defaults:

- **Clock 3 = 250 kHz** — residue / z-loop tick clock
- **Clock 2 = 750 kHz** (kbee-04 only) — accumulator sub-tick clock

Spell these out as "Clock 3 (250 kHz default)" or "Clock 2 (750 kHz)" in build
guides; `ClockA` is the per-CAM dropdown that *selects* a global slot, not a
global clock itself.

### 5. Save early, save often

After every CAM placement or wire change, `Ctrl+S`.

### 6. Analog MUX idiom (locked in by kbee-03, 2026-04-23)

To multiplex two analog signals under digital-ish control:

- **`GainSwitch` CAM** with both gains set to **1.0** and "Select Input 1 When
  Control High". Input 1 = branch A, Input 2 = branch B, Control = mux select.
- Drive Control from a **differential analog siggen** (`CM = 1.5 V`, Diff Offset
  ≈ 1 V for HIGH, 0 V for LOW).
- If either branch comes from a half-cycle SC CAM, insert a **plain `Hold` CAM**
  (bridge hold) with **Input Sampling Phase matched to the upstream CAM's Output
  Phase**.

`HoldVoltageControlled` is **not** a drop-in analog mux.

### 7. Loop latency budget (locked in by kbee-03, 2026-04-23)

Any SC feedback loop that uses Holds for phase-bridging adds **one Clock 3
period per Hold** of startup latency. The kbee-03 residue loop has two Holds in
series, giving **8 µs seed-to-first-residue** at 250 kHz.

When a downstream stage needs to align a strobe with the residue cascade, wait
at least **N × 4 µs** after `Load` falls, where `N` is the number of Holds in
series in that loop.

### 8. GainSwitch analog-output 1-tick delay (locked in by kbee-03, 2026-04-23)

A GainSwitch CAM's analog output lags its Control input by one full clock cycle.
Downstream consumers see `Control[previous clock]`, not `Control[current clock]`.

When precision matters (kbee-04, kbee-05), insert a `Hold` in the `z` branch
before the SumDiff so both the `3·z` term and the classifier-output term reflect
`z[n−1]`. See rule 9 for the sampling-phase pairing that makes this work.

### 9. Two-Holds-in-series phase rule (locked in by kbee-03, 2026-04-24)

When chaining two `Hold` CAMs for pipeline-matching, their **Input Sampling Phases
must be opposite**, not identical.

Correct pattern for a full one-clock delay:

- Upstream Hold: **Sampling Phase = Φ1** (or whatever matches its upstream).
- Downstream Hold: **Sampling Phase = Φ2** (opposite of upstream).
