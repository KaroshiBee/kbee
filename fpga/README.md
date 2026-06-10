# KBee digital FPGA (Hardcaml)

Digital FPGA implementation of the W=8 kbee algorithm using **pause-encoded
arithmetic** on a free-running sawtooth counter. Distinct from:

| Tree | Substrate |
|------|-----------|
| [`fpaa/`](../fpaa/) | Anadigm AN231E04 analog FPAA (AD2 sim + hardware) |
| [`asic/`](../asic/) | Sky130 analog current-mode cell |
| **`fpga/`** (here) | Open digital FPGA path (e.g. Tiny Tapeout) |

## Pause encoding

The master timebase is a 13-bit sawtooth `phase ∈ [0, 6560]` (`P = 6561 = 3^8`)
that increments every clock and wraps. Operands and internal state are **pause
durations** on pausable samplers sharing that sawtooth:

| Primitive | Effect |
|-----------|--------|
| `pause(n)` | Hold sampler frozen for `n` ticks while phase advances |
| `pause_add(x, y)` | `pause(x)` then `pause(y)` → lag encodes `x + y` |
| `pause_triple()` | `sample` current `v`, then `pause(v)` twice → `3v mod P` |

Modular subtraction is **free** via sawtooth wrap (`3·2187 = P`, `3·4374 = 2P`);
the residue step is uniform every tick: classify → `pause(inc_k)` on the winning
accumulator → `pause_triple()`.

The FPAA path needs explicit `SumDiff` subtracts on a bounded voltage rail; the
cyclic digital sawtooth does not.

## Specification

- Algorithm: [`docs/base-n-nminus1-algorithm.md`](../docs/base-n-nminus1-algorithm.md)
- Machine-checked proofs: [`proofs/`](../proofs/) (Lean 4)
- Executable oracle: [`python/kbee.py`](../python/kbee.py)
- W=8 reference CSV: [`data/kbee-w8-refs.csv`](../data/kbee-w8-refs.csv)

## Toolchain

```bash
nix develop .#fpga
```

Provides OCaml 5.3, Dune, and **Hardcaml 0.17.0** via [`nix/overlay.nix`](nix/overlay.nix).

## Build and test

From `fpga/`:

```bash
dune build
dune runtest
```

Tests:

- `test_sawtooth` — sawtooth wrap period `P`
- `test_pause` — `pause_add`, `pause_triple` vs oracle lag math
- `test_kbee_sum` — exhaustive `x + y` for `x, y ∈ [0, 3280]`
- `test_kbee_cell` — full cell vs CSV (65536 rows) and HardCaml cycle sim

## Module map

| Module | Role |
|--------|------|
| `Sawtooth` | Master phase counter + wrap strobe |
| `Pausable_sampler` | `lag = phase − ptr (mod P)` |
| `Pause_sim` | Cycle-accurate reference model |
| `Kbee_cell` | Top FSM: sum → 8-tick residue + accumulators |

## Cycle budget (informative)

Literal pause encoding is slow but faithful:

- Sum: `x + y ≤ 6560` ticks
- Per residue tick: up to `3z` pause ticks on the triple step
- Accumulators: `Σ inc_k = 3280` pause ticks across winning branches

Expect **O(10⁵–10⁶) cycles/op** in simulation. Throughput optimisations can
collapse pause sequences later without changing semantics.

## Next steps

- Controller/timing formal model (TLA+ or [Veil](https://github.com/verse-lab/veil/))
- Target FPGA board integration when moving beyond sim-first milestone
