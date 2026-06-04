# KBee

Open research and reference designs for the **KBee** multi-gate analog compute
cell — from algorithm oracle through **Anadigm AN231E04** FPAA bring-up to
**sky130** ASIC experiments.

## Licensing

| Part | Paths | License |
|------|-------|---------|
| Software | `python/`, `scripts/`, `fpaa/scripts/`, `proofs/`, `data/*.csv`, `fpaa/data/*.csv` | [LGPL-3.0-or-later](LICENSE) |
| Hardware | `fpaa/designs/*.ad2`, `asic/` | [CERN-OHL-W-2.0-or-later](LICENSE-HARDWARE) |
| Documentation | `docs/`, `fpaa/docs/`, `fpaa/designs/reports/` | [CC BY-SA 4.0-or-later](LICENSE-DOCUMENTATION) |

Proprietary tools and silicon (AnadigmDesigner2, AN231E04) are **not** included —
see [THIRD_PARTY.md](THIRD_PARTY.md). OSHWA certification is planned for the
**kbee-04 FPAA reference** and other hardware components once the public remote is live.

## Project goal

Build the analog substrate for a **RISC-V** implementation using the **KBee** cell described in [`docs/base-n-nminus1-algorithm.md`](docs/base-n-nminus1-algorithm.md).

## Current status

**kbee-04** is the first published design stage. Earlier bring-up designs
(kbee-00 through kbee-03) are referenced in docs but not included in this
repository.

- **Active FPAA design:** `fpaa/designs/kbee-04.ad2` a prototype implementation of a ternary, 4-digit KBee cell (residue + NOR/XOR/AND accumulators).
- **Build guide:** [`fpaa/docs/kbee-04-full.md`](fpaa/docs/kbee-04-full.md).
- **Bring-up:** [`fpaa/docs/kbee-04-hw-bringup-checklist.md`](fpaa/docs/kbee-04-hw-bringup-checklist.md).
- **Baselines** Pulse/zero timing baseline: `A=32 µs`, `B=8 µs`.
- **Algorithm oracle:** [`python/kbee.py`](python/kbee.py) + [`data/kbee-w8-refs.csv`](data/kbee-w8-refs.csv).
- **Proofs** [`proofs/README.md`](proofs/README.md) Lean4 proofs of the general KBee cell base-N arithmetic.
- **Prototype ASIC** [`asic/`](asic/) early work on an asic design for a base-4, 4-digit KBee cell.

## Quick start

```bash
nix develop
nix develop -c check-kbee              # format + license/copyright (pre-push gate)
nix develop -c install-git-hooks       # pre-push hook (runs check-kbee)
nix develop -c format-kbee             # format tracked py/sh/nix/md/toml/yaml
nix develop -c gen-kbee-refs           # regenerate data/kbee-w8-refs.csv
```

## Repository layout

See [`docs/REPO_LAYOUT.md`](docs/REPO_LAYOUT.md) for the full tree.

```
python/           Reference oracle and tests
data/             Generated reference CSVs
docs/             Algorithm spec and summaries
proofs/           Lean 4 proofs
fpaa/designs/     AnadigmDesigner2 .ad2 projects
fpaa/docs/        FPAA build guides and chip notes
fpaa/data/        Simulation traces (AD2 scope CSV)
asic/             sky130 xschem + Ngspice
fpga/             Future digital work (placeholder)
scripts/          Top level helper scripts
```

## Python

Executable reference oracle for the base-N, N−1-input algorithm. See
[`python/README.md`](python/README.md) and
[`docs/base-n-nminus1-algorithm.md`](docs/base-n-nminus1-algorithm.md).

### Tests

```bash
nix develop -c run-kbee-tests
```

Property tests at W=4, W=16, and W=32 (`python/test/`).

### Reference CSVs

```bash
nix develop -c gen-kbee-refs              # W=8 -> data/kbee-w8-refs.csv
nix develop -c gen-kbee-base4-w4-refs    # W=4 base-4 -> data/kbee-base4-w4-refs.csv
```

## Lean

Machine-checked verification of the generic algorithm in Lean 4. See
[`proofs/README.md`](proofs/README.md).

### Build

```bash
cd proofs && nix develop -c lake build Kbee
```

Covers carry-free sum, MSB-first residue extraction, gate accumulators, and
end-to-end NOR/AND/XOR/XNOR theorems. FPAA timing, load/strobe sequencing, and
analog pipeline delays are out of scope.

## FPAA

### Opening an FPAA design

```bash
nix develop -c open-ad2
nix develop -c open-ad2 fpaa/designs/kbee-04.ad2
```

Requires AnadigmDesigner2 via Wine (`fpaa` on PATH, or set `$FPAA_BIN`).
Inside `nix develop`, `open-ad2` is on PATH directly.

### Target FPAA hardware

- Chip: **AN231E04** (4 CABs)
- Tool: **AnadigmDesigner2** (Wine)
- Dev environment: Nix (`flake.nix`)

## ASIC

### ASIC iic-osic-tools container

```bash
nix develop
iic-osic-tools                 # interactive shell in the container
iic-osic-tools yosys -V        # run a tool directly
iic-osic-tools --ui-local --wait
```

Overrides: `IIC_OSIC_TOOLS_IMAGE`, `IIC_OSIC_WORKDIR`, `IIC_OSIC_UI_HTTP_PORT`, `IIC_OSIC_UI_VNC_PORT`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bugs and design questions:
[Codeberg issues](https://codeberg.org/Karoshibee/kbee/issues).
