# kbee-04 hardware preflight log

> **Scope:** checker-pipeline validation only. This run exercised the gate
> scripts against existing reference captures (`fpaa/data/kbee-04-*.csv`), not
> live AN231K04 bench hardware. The gate-runner stdout was not archived in
> this repo.

- Date: 2026-05-19
- Operator: Codex (prep pass)
- Board: AN231K04 (not connected — pipeline validation)
- Host: (not recorded)
- Git SHA: (pre-public history; not applicable to current tree)

## Phase 0 bench readiness

- Hardware unpack/connect: pending physical action.
- AD2 board detection: pending physical action.
- This preflight run validates the full checker pipeline and artifacts using
  existing reference captures.

## Frozen artifacts verified

- `fpaa/designs/kbee-04.ad2`
- `fpaa/designs/reports/kbee-04/kbee-04.htm`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-x.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-y.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+2us.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+4us.csv`
- `fpaa/data/waveforms/zsum-4trit-81-1x-A32-B8-v1p2-load-accum-delay+6us.csv`

## Checker sequence evidence

- Command:
  - `fpaa/scripts/kbee-04-hw-gate-runner.sh --residue fpaa/data/<residue-capture>.csv --nor fpaa/data/<nor-capture>.csv --nor-or fpaa/data/kbee-04-nor-or-04.csv --nand-and fpaa/data/kbee-04-nand-and-04.csv --xor-xnor fpaa/data/kbee-04-nxor-xor-04.csv`
- Result:
  - Residue gate: PASS
  - NOR gate: PASS
  - NOR/OR invariant: PASS (`max_abs_error_mv=0.012407`)
  - NAND/AND invariant: PASS (`max_abs_error_mv=0.012407`)
  - XOR/XNOR invariant: PASS (`max_abs_error_mv=0.012407`)

## Next action to enter live bench testing

1. Unpack and connect AN231K04 board.
1. Confirm board is visible/selectable in AD2.
1. Re-run the same gate runner command using fresh bench captures and record
   results in a new `data/hw-runs/YYYY-MM-DD-kbee-04-hw-log.md`.
