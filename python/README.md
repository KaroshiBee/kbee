# Python reference oracle

Executable reference for the base-N, N−1-input algorithm from
[`docs/base-n-nminus1-algorithm.md`](../docs/base-n-nminus1-algorithm.md).

## Role in the stack

| Layer | Location |
|-------|----------|
| Math spec | `docs/base-n-nminus1-algorithm.md` |
| Machine-checked proofs | `proofs/` (Lean 4) |
| Executable oracle | `python/kbee.py` |
| W=8 reference CSV | `data/kbee-w8-refs.csv` (from `scripts/gen-kbee-refs.py`) |
| W=4 base-4 ASIC CSV | `data/kbee-base4-w4-refs.csv` (from `scripts/gen-kbee-base4-w4-refs.py`) |
| Analog realisation | `fpaa/` (base-3 voltage) · `asic/` (base-4 current) |
| Digital FPGA (future) | `fpga/` |

## Coverage

- **`Gates2Inputs(bitwidth)`** — base-3, two-input; `make4Bit`, `make16Bit`, `make32Bit`.
- **`Gates3InputsBase4`** — base-4, W=4, three-input ASIC oracle (`eval_cell`, `eval_fabric`, `residue_trace`).
- **`scripts/gen-kbee-base4-w4-refs.py`** — exhaustive `(A,B,C,ui_in)` table for Ngspice.
- **Property tests** — Hypothesis checks at W=4, W=16, and W=32 (broader than the W=8 CSV).

## Tests

From the repo root:

```bash
nix develop -c run-kbee-tests
```

Or:

```bash
export PYTHONPATH="$PWD/python${PYTHONPATH:+:$PYTHONPATH}"
python -m unittest discover -s python/test -p 'test_*.py'
```

## Generate reference CSV

```bash
nix develop -c gen-kbee-refs
```
