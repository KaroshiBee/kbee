# Time-paused sampling — design notes (FPGA)

This tree is the **time-based** digital kbee prototype: operands and internal
state are pause durations on a shared sawtooth. That model is intentional and
stays here.

**Direct modular arithmetic** (collapsed schedules, current-domain rails, explicit
`SumDiff`-style subtracts) is explored in [`../../asic/`](../../asic/) and in the
FPAA bring-up under [`../../fpaa/`](../../fpaa/). Those paths use
[`python/kbee.py`](../../python/kbee.py) / [`Oracle_lag`](../lib/oracle_lag.ml) as
the functional oracle; they do not replace the pause-encoded reference in this
tree.

## What we implement today

| Piece | Module | Mechanism |
|-------|--------|-----------|
| Global timebase | `Sawtooth` | 13-bit `phase`, wraps at `P = 6561` |
| Sampler lag | `Pausable_sampler` | `ptr` tracks `phase` when enabled; `lag = phase − ptr (mod P)` |
| Cell FSM pauses | `Kbee_cell` | `countdown` register decrements each tick until zero |

The sawtooth is one counter per chip; cells share `phase` / `wrap` via
`Kbee_system` (see [`README.md`](../README.md)).

## Can pause sampling avoid counters?

Not entirely. Discrete pause-by-`n` ticks needs **Ω(log n) bits of elapsed-time
state** somewhere. You can **relocate** counters, not remove timekeeping without
changing the model.

What you *can* change is **which** counter and **how** you wait.

### Deadline compare (recommended FPGA refactor)

Keep the shared sawtooth; replace per-pause **countdown decrement** with a
latched **deadline**:

```
end_phase = (phase_now + n) mod P   -- captured at pause start
done      = (phase == end_phase)
```

Still one global `phase` counter; each pause holds one `end_phase` register and
a comparator instead of a ticking countdown. Same pause semantics; often
cleaner timing and slightly lower toggle rate than ripple decrement.

### Shift-register delay line

Pause `n` = signal tapped `n` flip-flops down a fixed chain. No countdown FSM,
but **O(n) FFs per line** and poor scaling when `n` can reach ~6560.

### Phase-indexed ring buffer

`phase` walks a circular RAM address; freeze a read pointer on disable; lag from
address difference. Equivalent to `ptr` + combinatorial subtract; `phase` remains
a counter.

### Event scheduling (simulation / many parallel pauses)

Oracle or controller jumps to the next `phase` where any deadline fires (timer
wheel, priority queue keyed by phase). Hardware still needs a global time
coordinate.

### Analog time (FPAA — not this tree)

Continuous ramp / integrator voltage plus sample-and-hold: no *digital* counter,
but DAC settling, drift, and rail bounds. Documented under `fpaa/`; the digital
FPGA path uses a cyclic sawtooth instead.

### Direct calculation (out of scope here)

[`Oracle_lag`](../lib/oracle_lag.ml) runs the 8-tick kbee loop in integer math
with no pause simulation. Same inputs/outputs as the time model; used to check
correctness and as the spec for ASIC/FPAA direct implementations. **Not** the
substrate for this FPGA prototype.

## Division of labour across repos

| Tree | Time model | Arithmetic style |
|------|------------|------------------|
| **`fpga/`** (here) | Yes — sawtooth + pause | Digital pause encoding |
| [`fpaa/`](../fpaa/) | Yes — SC clock phases, analog rails | Modular subtract on bounded voltage |
| [`asic/`](../asic/) | No — current-domain settling | Direct / modular (current steering) |

When adding features, keep time-paused semantics in `fpga/` and point
performance or density work at `asic/` (or collapsed HardCaml only as an
**oracle check**, not as a replacement top-level).

## Open work (time model retained)

- Refactor `Kbee_cell` countdown states to deadline-compare against shared
  `phase` (same semantics, fewer decrement toggles).
- Controller / timing formal model (TLA+ or [Veil](https://github.com/verse-lab/veil/)).
