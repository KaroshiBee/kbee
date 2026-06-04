# Oracle reference data

Platform-neutral ground-truth tables generated from the Python reference oracle
(`python/kbee.py`).

## Canonical files

| File | Rows | Generator |
|------|------|-----------|
| `kbee-w8-refs.csv` | 65536 | `scripts/gen-kbee-refs.py` |
| `kbee-base4-w4-refs.csv` | 65536 | `scripts/gen-kbee-base4-w4-refs.py` |

Regenerate:

```bash
nix develop -c gen-kbee-refs
nix develop -c gen-kbee-base4-w4-refs
```

## Layout

- **`data/`** (this directory) — algorithm oracle CSVs used by picks scripts and FPAA docs.
- **`fpaa/data/`** — AD2 waveforms, scope captures, and bench-specific CSVs only.

Top-level `data/` is canonical for algorithm oracle tables. Bench and simulation
CSVs live under `fpaa/data/`.
