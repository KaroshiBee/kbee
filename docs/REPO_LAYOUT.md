# Repository layout

Quick map of the current tree and where to start.

## Canonical (start here)

| Path | Purpose |
|------|---------|
| [`python/kbee.py`](../python/kbee.py) | Algorithm oracle (ground truth) |
| [`data/kbee-w8-refs.csv`](../data/kbee-w8-refs.csv) | W=8 reference table (`nix develop -c gen-kbee-refs`) |
| [`docs/base-n-nminus1-algorithm.md`](base-n-nminus1-algorithm.md) | Math spec |
| [`docs/ad2-conventions.md`](ad2-conventions.md) | AD2 / FPAA bring-up conventions |
| [`proofs/`](../proofs/) | Lean 4 proofs |
| [`fpaa/designs/kbee-04.ad2`](../fpaa/designs/kbee-04.ad2) | Active FPAA design (residue + accumulators) |
| [`fpaa/docs/kbee-04-full.md`](../fpaa/docs/kbee-04-full.md) | Build guide for kbee-04 |
| [`fpaa/docs/kbee-04-hw-bringup-checklist.md`](../fpaa/docs/kbee-04-hw-bringup-checklist.md) | Dev-board bring-up |
| [`fpaa/docs/AN231E04.md`](../fpaa/docs/AN231E04.md) | Chip / AD2 notes |
| [`fpaa/scripts/`](../fpaa/scripts/) | Active waveform generators and bench checkers |
| [`asic/`](../asic/) | sky130 schematic + Ngspice path (base-4 cell) |

## Other top-level trees

| Path | Purpose |
|------|---------|
| [`fpga/`](../fpga/) | Future digital FPGA work (placeholder README) |
| [`scripts/`](../scripts/) | Oracle reference generators (LGPL-3.0-or-later) |

## External (local, not in this repo)

- **`KBEE_KB`** — root of your local Anadigm CAM knowledge-base checkout
  (`cam-docs/` under it). See [`ad2-conventions.md`](ad2-conventions.md).

## Do not commit

- `.hypothesis/` — local test cache
