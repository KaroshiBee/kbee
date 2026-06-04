# KBee digital FPGA (Hardcaml)

Future home for a **digital** FPGA implementation of the base-N algorithm, distinct from:

| Tree | Substrate |
|------|-----------|
| [`fpaa/`](../fpaa/) | Anadigm AN231E04 analog FPAA (AD2 sim + hardware) |
| [`asic/`](../asic/) | Sky130 analog current-mode cell |
| **`fpga/`** (here) | Open digital FPGA path (e.g. Tiny Tapeout) |

## Specification

- Algorithm: [`docs/base-n-nminus1-algorithm.md`](../docs/base-n-nminus1-algorithm.md)
- Machine-checked proofs: [`proofs/`](../proofs/) (Lean 4)
- Executable oracle: [`python/kbee.py`](../python/kbee.py)

Simulations and tests should cross-check against the Python oracle before tapeout.

## Toolchain

```bash
nix develop .#fpga
```

This shell provides OCaml, Dune, Merlin, and a pinned **Hardcaml 0.17.0** overlay
(from the kbee Python oracle lineage) via [`nix/overlay.nix`](nix/overlay.nix).

There is no buildable OCaml library yet — add `lib/` when implementation starts.

## Next steps

1. First Hardcaml module implementing W-tick residue extraction + gate accumulators.
1. Cycle-accurate tests against `python/kbee.py` at W=8 (then wider words).
1. Controller/timing model — consider TLA+ or [Veil](https://github.com/verse-lab/veil/)
   for Load/strobe sequencing (see [`docs/summary.md`](../docs/summary.md)).
