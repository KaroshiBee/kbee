# KBee ASIC (base-4, current domain)

Pass-1 implementation.

| Doc | Purpose |
|-----|---------|
| [`docs/summary.md`](docs/summary.md) | Pin/mode contract |
| [`docs/phase-02-fabric.md`](docs/phase-02-fabric.md) | Residue fabric + pass-1 scope |
| [`layout/kbee_tile.md`](layout/kbee_tile.md) | Preliminary sky130 floorplan |

## Quick start

```bash
nix develop .#asic                        # ASIC dev shell
nix develop .#asic -c gen-kbee-base4-w4-refs   # golden CSV
nix develop -c run-kbee-tests             # Python oracle tests (default shell)
nix develop .#asic -c check-asic-csv --only-equiv --max-rows 5000
nix develop .#asic -c run-asic-sim        # Ngspice benches
python asic/scripts/compare-ngspice-fabric.py
```

sky130 device sketches: `ngspice/sky130/`. Full PDK via `iic-osic-tools` when needed.
