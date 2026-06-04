# Third-party components

KBee open-source releases include **our** hardware designs, software, and
documentation. Several dependencies are proprietary or maintained by others.
This file lists them so OSHWA certification and downstream users can see what
is *not* covered by our licenses.

## Proprietary (not redistributed from this repo)

| Component | Role | Notes |
|-----------|------|--------|
| **AnadigmDesigner2** | Edit and simulate `.ad2` FPAA designs | Commercial Windows tool; run under Wine on Linux. Design source files in `fpaa/designs/` are ours (CERN-OHL-W); the tool is not. |
| **Anadigm CAM help (CHM)** | CAM parameter reference | Shipped with AD2. Build a local Markdown KB outside this repo (`KBEE_KB`; see [`docs/ad2-conventions.md`](docs/ad2-conventions.md)). Do not commit converted Anadigm HTML. |
| **AN231E04 FPAA** | Target analog silicon | Anadigm part (legacy). Datasheet and dev-board docs are third-party; see `fpaa/docs/AN231E04.md`. |
| **AN231K04 dev board** | Hardware bring-up | Third-party board around the AN231E04. |

## Open toolchain / PDK (used, not owned by us)

| Component | Role | License / access |
|-----------|------|------------------|
| **SkyWater sky130** | ASIC PDK for `asic/` experiments | Open PDK; see [sky130](https://github.com/google/skywater-pdk). |
| **Ngspice, Xschem, Magic, …** | ASIC simulation and layout | Various OSS licenses via Nix / `iic-osic-tools` image. |
| **Tiny Tapeout** (planned) | MPW shuttle for silicon validation | Submission flow requires open design; separate from this repo. |

## Software dependencies (see also `flake.nix`)

Python (NumPy, Hypothesis), Lean 4, Docker image `hpretl/iic-osic-tools`, and
Nixpkgs packages are standard open-source dependencies with their own licenses.

## What we license

| Path | License |
|------|---------|
| `python/`, `scripts/`, `proofs/` (Lean sources) | LGPL-3.0-or-later — see `LICENSE` |
| `fpaa/designs/`, `asic/` schematics/netlists | CERN-OHL-W-2.0-or-later — see `LICENSE-HARDWARE` |
| `docs/`, `fpaa/docs/`, `fpaa/designs/reports/` | CC BY-SA 4.0-or-later — see `LICENSE-DOCUMENTATION` |
| `data/*.csv` | LGPL-3.0-or-later (generated reference data; same as oracle) |

Simulation CSVs under `fpaa/data/` are reference artefacts (LGPL-3.0-or-later)
unless a file header states otherwise.
