# Residue Pulse/Zero Baseline (Active Set)

This directory contains several waveform variants; the canonical residue
validation set is:

- `zsum-4trit-81-1x-A32-B8-v1p2-x.csv`
- `zsum-4trit-81-1x-A32-B8-v1p2-y.csv`
- `zsum-4trit-81-1x-A32-B8-v1p2-load.csv`

These are the canonical 4-trit exhaustive inputs (81 codes, `0000..2222`)
using:

- active window `A = 32 us`
- zero window `B = 8 us`
- `Load`: `+0.5 V` for `8 us`, then `-0.5 V`
- `V_range = 1.2 V`

Expected sim duration for one full sweep: `81 * (32 + 8) us = 3.24 ms`
(run `3.2-3.3 ms` for margin).

## Regeneration

```bash
python3 fpaa/scripts/gen-zsum-4trit-81-pulse-zero.py
```
