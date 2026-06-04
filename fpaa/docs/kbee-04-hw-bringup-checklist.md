# kbee-04 hardware bring-up checklist

This checklist is the pre-bench lock for the current kbee-04 flow. It captures
the exact artifacts, probe maps, checker commands, and pass/fail gates so runs
are reproducible.

All paths below are relative to the **repository root**.

## 0) Bench-first bring-up sequence (run this top-to-bottom)

Stop immediately on any failed gate; do not continue to later stages.

### 0.1 Physical and tool bring-up

1. Connect AN231K04 board and USB/JTAG interface.
1. Launch AD2 and open `fpaa/designs/kbee-04.ad2`.
1. Confirm board is detected/selectable in AD2 target hardware menu.
1. Program/download the design once and confirm no target/program errors.

Pass gate:

- board visible in AD2
- programming step succeeds

### 0.2 Clock and waveform sanity

1. Confirm `Clock 3 = 250 kHz` in the active design configuration.
1. Load baseline stimulus files (`x`, `y`, `load`) into the run setup.
1. Run a short capture and verify `Load` pulse period is `40 us` (`32 us` high + `8 us` low).

Pass gate:

- measured `Load` timing matches the locked A32/B8 plan

### 0.3 Probe-map sanity capture

Use residue map (`Ch1=Load`, `Ch2=oneOrTwo`, `Ch3=isTwo`, `Ch4=z_hold`) and run
a short capture to verify:

- channel polarity/sign conventions are correct
- `z_hold` moves away from rail-collapse values after startup
- rails (`oneOrTwo`, `isTwo`) toggle across windows

Pass gate:

- channels decode as expected and are stable enough for full-run capture

### 0.4 Full validation sequence

Run these in order:

1. Residue 81-case gate
1. NOR accumulator 81-case gate
1. NOR/OR invariant
1. NAND/AND invariant
1. XOR/XNOR invariant

Pass gate:

- all five checks pass with zero hard mismatches and invariant errors within threshold

## 1) Freeze the artifact set

- **Design file:** `fpaa/designs/kbee-04.ad2`
- **Design report:** `fpaa/designs/reports/kbee-04/kbee-04.htm`
- **Residue stimuli (A32/B8):**
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-x.csv`
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-y.csv`
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load.csv`
- **Accumulator delayed-load variants (if used):**
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+2us.csv`
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+4us.csv`
  - `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+6us.csv`

Record the git SHA used for the bench run in the capture log.

## 2) Timing constants (locked for current flow)

- `Clock 3 = 250 kHz` (4 us SC tick)
- 4-trit active window: `32 us`
- zero window between codes: `8 us`
- per-code period: `40 us`
- full 81-code run: `3.24 ms` (use `3.3-3.5 ms` capture for margin)

## 3) Scope/probe maps

Use one map at a time; do not mix channels between maps when decoding.

- **Residue check map**
  - `Ch1`: `Load`
  - `Ch2`: `oneOrTwo`
  - `Ch3`: `isTwo`
  - `Ch4`: `z_hold`
- **NOR accumulator check map**
  - `Ch1`: NOR accumulator `Load`
  - `Ch2`: `oneOrTwo`
  - `Ch3`: `isTwo`
  - `Ch4`: `nor_hold`
- **Complement-pair invariant map** (one pair per run)
  - `Ch1`: accumulator `Load`
  - `Ch2`: classifier control rail (for context)
  - `Ch3`: branch A
  - `Ch4`: branch B

Examples:

- NOR/OR -> `Ch3=NOR`, `Ch4=OR`
- NAND/AND -> `Ch3=NAND`, `Ch4=AND`
- XOR/XNOR -> `Ch3=XOR`, `Ch4=XNOR`

## 4) Pre-run bench calibration sanity

Before full 81-case captures:

- verify `Load` high/low levels and pulse width at the pin
- verify one known reference level (`V_unit`) and full-scale ones level
  (`R_W * V_unit`, where `R_W=(3^W-1)/2`; for `W=4`, `R_W=40`)
- confirm channel polarity/sign conventions once, then keep fixed

## 5) Residue 81-case gate check

Run the residue checker with 8 us checkpoints:

```bash
python3 fpaa/scripts/kbee-03-check-81-pulse-zero.py \
  fpaa/data/<your-residue-capture>.csv \
  --checkpoints-us 8,16,24,32,40
```

Pass gate:

- 81 load windows
- seed order `0000..2222`
- zero in-window and cross-window mismatches

## 6) NOR accumulator 81-case check (delayed-load aligned)

For the current delayed-load setup, use the locked offsets:

```bash
python3 fpaa/scripts/kbee-04-check-nor-pulse-zero.py \
  fpaa/data/<your-nor-capture>.csv \
  --run-sample-offsets-us 8,16,24,32 \
  --final-offset-us 42
```

Pass gate:

- 81 load windows
- zero rail mismatches
- zero final-code mismatches

## 7) Complement-pair invariants

For each pair (`NOR+OR`, `NAND+AND`, `XOR+XNOR`), verify:

- `Ch3 + Ch4 = R_W * V_unit` after startup
- for `W=4`, `V_range=1.2`: target `0.5925926 V`
- expected residual is quantisation-scale only (~0.01 mV in recent runs)

Record max absolute error and mean absolute error per run.

## 8) Suggested run order

1. Residue 81-case check
1. NOR accumulator 81-case check
1. NOR/OR invariant
1. NAND/AND invariant
1. XOR/XNOR invariant

If a step fails, stop and fix before proceeding to later steps.

## 9) Run log template

For each capture, log:

- file path
- probe map used
- waveform files used
- checker command used
- pass/fail + key metrics (window count, mismatch counts, max error)
- git SHA

Store run logs under:

- `data/hw-runs/`

Optional one-command sequence runner (uses the same checker scripts/gates):

```bash
fpaa/scripts/kbee-04-hw-gate-runner.sh \
  --residue fpaa/data/<residue-capture.csv> \
  --nor fpaa/data/<nor-capture.csv> \
  --nor-or fpaa/data/kbee-04-nor-or-04.csv \
  --nand-and fpaa/data/kbee-04-nand-and-04.csv \
  --xor-xnor fpaa/data/kbee-04-nxor-xor-04.csv \
  --out data/hw-runs/<run-name>.log
```
