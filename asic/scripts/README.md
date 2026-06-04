# ASIC scripts

- `run-sim.sh` — batch Ngspice benches (`nix develop -c run-asic-sim`)
- `check-vs-csv.py` — oracle vs `data/kbee-base4-w4-refs.csv` (`nix develop -c check-asic-csv`)
- `compare-ngspice-fabric.py` — spot-check spice `Vy` against Python oracle corners
