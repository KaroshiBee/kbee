# Scripts (Active Pulse/Zero Flow)

Run all commands from the **repository root** unless a path is given as absolute.

This folder keeps only the active scripts for the phase-03 residue pulse/zero
validation workflow (`A=32 us`, `B=8 us`).

## Active Scripts

- `gen-zsum-4trit-81-pulse-zero.py`
  - canonical waveform generator for the full 81-code sweep
- `gen-zsum-pick-sequence-waveforms.py`
  - custom pick-sequence waveform generator with active/zero windows
- `kbee-03-check-81-pulse-zero.py`
  - one-command validator for exhaustive 81-case pulse/zero captures
- `kbee-04-check-nor-pulse-zero.py`
  - validator for NOR accumulator pulse/zero captures
- `kbee-04-check-complement-pair.py`
  - invariant checker for complement pairs (`A + B = R_W * V_unit`)
- `kbee-04-hw-gate-runner.sh`
  - one-command sequence runner for residue/NOR/complement bench gates

## Standard Commands

### 1) Canonical exhaustive 81-case waveform generation

```bash
python3 fpaa/scripts/gen-zsum-4trit-81-pulse-zero.py
```

Writes:

- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-x.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-y.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load.csv`

`x` and `y` are split so `x + y` reproduces the canonical residue target that
used to be emitted as a single `zsum` waveform.

Standard sim duration: `3.2-3.3 ms` (nominal `3.24 ms`).

### 2) Canonical exhaustive 81-case capture validation

```bash
python3 fpaa/scripts/kbee-03-check-81-pulse-zero.py \
  fpaa/data/<your-residue-capture>.csv
```

This checks:

- 81 load windows detected
- seed order `0000..2222`
- delayed rail consistency inside each window and across windows

### 2b) NOR accumulator validation (locked offsets)

```bash
python3 fpaa/scripts/kbee-04-check-nor-pulse-zero.py \
  fpaa/data/<your-nor-capture>.csv \
  --run-sample-offsets-us 8,16,24,32 \
  --final-offset-us 42
```

### 2c) Complement-pair invariant validation

```bash
python3 fpaa/scripts/kbee-04-check-complement-pair.py \
  fpaa/data/kbee-04-nor-or-04.csv \
  --start-us 40
```

### 2d) Full kbee-04 bench gate sequence

```bash
fpaa/scripts/kbee-04-hw-gate-runner.sh \
  --residue fpaa/data/<residue-capture>.csv \
  --nor fpaa/data/<nor-capture>.csv \
  --nor-or fpaa/data/kbee-04-nor-or-04.csv \
  --nand-and fpaa/data/kbee-04-nand-and-04.csv \
  --xor-xnor fpaa/data/kbee-04-nxor-xor-04.csv \
  --out data/hw-runs/preflight-gate-run.log
```

### 3) Common custom-sequence waveform generation (bring-up/debug)

```bash
python3 fpaa/scripts/gen-zsum-pick-sequence-waveforms.py \
  --codes "0001,1111,2222,1201,2101" \
  --width 4 \
  --v-range 1.2 \
  --active-us 48 \
  --zero-us 12 \
  --repeats 5 \
  --load-high-us 12 \
  --load-high-v 0.5 \
  --load-low-v -0.5 \
  --out-base "zsum-picks-0001-1111-2222-1201-2101-5x-A48-B12"
```

Standard sim duration for that example: `1.55 ms` (nominal `1.50 ms`).

## AD2 helpers

- `open-ad2` — launch AnadigmDesigner2 (`nix develop .#fpaa`; requires Wine `fpaa` on PATH)
