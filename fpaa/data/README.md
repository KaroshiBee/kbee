# Data Layout (Active)

The active residue/accumulator test flow is centered on pulse/zero testing:

- full 4-trit sweep (`81` values)
- active window `A = 32 us`
- zero window `B = 8 us`

## Active Data

- `fpaa/data/waveforms/` — stimulus CSVs for AD2 simulation and bench runs.
- `fpaa/data/kbee-04-*.csv` — complement-pair and accumulator scope captures
  used by the hardware gate checkers (see `fpaa/scripts/README.md`).
- Algorithm oracle tables live at the repo root: `data/kbee-w8-refs.csv`
  (see `data/README.md`).
