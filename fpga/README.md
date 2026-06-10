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

This tree **keeps the time-paused model** as the prototype substrate. Direct
modular arithmetic (collapsed schedules, current-domain rails) lives under
[`asic/`](../asic/) and [`fpaa/`](../fpaa/). See
[`docs/time-model.md`](docs/time-model.md) for pause alternatives (e.g.
deadline-compare vs countdown) without abandoning the time model here.

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

Ground-truth oracle outside this tree: [`python/kbee.py`](../python/kbee.py) →
[`data/kbee-w8-refs.csv`](../data/kbee-w8-refs.csv).

### Oracle (plain OCaml — not synthesizable)

| Module | File | Role |
|--------|------|------|
| `Oracle_lag` | `lib/oracle_lag.ml` | Integer kbee math (direct oracle) |
| `Oracle_pause_sim` | `lib/oracle_pause_sim.ml` | Pause-encoded reference model |
| `Oracle_pause_primitives` | `lib/oracle_pause_primitives.ml` | Test helpers over oracle sim |
| `Oracle_pause_counter` | `lib/oracle_pause_counter.ml` | Unused OCaml countdown scaffold |

### HardCaml (synthesizable)

| Module | File | Role |
|--------|------|------|
| `Sawtooth` | `lib/sawtooth.ml` | Master phase counter + wrap strobe (one per chip) |
| `Pausable_sampler` | `lib/pausable_sampler.ml` | `lag = phase − ptr (mod P)` |
| `Kbee_cell` | `lib/kbee_cell.ml` | Cell FSM: sum → 8-tick residue + accumulators |
| `Kbee_top` | `lib/kbee_top.ml` | One cell + dedicated sawtooth (convenience wrapper) |
| `Kbee_system` | `lib/kbee_system.ml` | Two cells sharing one sawtooth |
| `Kbee_cell_sim` | `lib/kbee_cell_sim.ml` | Cycle-sim harness for `Kbee_top` (tests only) |

Instantiate **one** `Sawtooth` per FPGA and fan `phase` / `wrap` to every
`Kbee_cell`. Use `Kbee_top` when the design has a single cell; use
`Kbee_system` (or duplicate its `cell_on_bus` pattern) for several.

### Shared

| Module | File | Role |
|--------|------|------|
| `Params` | `lib/params.ml` | W=8 constants (`P`, `inc_schedule`, …) |

## Cycle budget (informative)

Literal pause encoding is slow but faithful:

- Sum: `x + y ≤ 6560` ticks
- Per residue tick: up to `3z` pause ticks on the triple step
- Accumulators: `Σ inc_k = 3280` pause ticks across winning branches

Expect **O(10⁵–10⁶) cycles/op** in simulation. That cost is accepted for this
prototype; faster direct implementations belong in other trees (see
[`docs/time-model.md`](docs/time-model.md)).

## Next steps

- Deadline-compare pauses (same semantics, less countdown toggling) — see
  [`docs/time-model.md`](docs/time-model.md)
- Controller/timing formal model (TLA+ or [Veil](https://github.com/verse-lab/veil/))
- Target FPGA board integration when moving beyond sim-first milestone
