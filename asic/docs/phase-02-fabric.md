# KBee ASIC phase 02 — reference fabric (base-4, W=4)

Pass-1 scope. Pin and mode contract:
[`summary.md`](summary.md). Oracle: `python/kbee.py` (`Gates3InputsBase4`).

## Numeric encoding

- Base `N = 4`, width `W = 4`, three operands `A`, `B`, `C`.
- Binary-format operands: each digit in `{0, 1}`; max code per lane
  `R_W = 1111_4 = 85`.
- Sum `z = A + B + C` in `[0, 255]` (`3333_4`); no inter-digit carry.
- **Nominal current:** `I = I_step * code` with `I_step = 50 nA` (grant text).
- **Simulation scale:** `I = k_scale * I_step * code` (default `k_scale = 1`;
  increase in Ngspice if mirror bias needs larger signals).

## Combinational residue unfold (default fabric)

MSB-first, four fixed stages (no feedback S&H in pass 1).

- `P = 4^{W-1} = 64`, `N^W = 256`.
- Leading digit `d` of current `z`:
  - `d = 0` if `z < P`
  - `d = 1` if `P <= z < 2P`
  - `d = 2` if `2P <= z < 3P`
  - `d = 3` otherwise
- Update: `z' = 4(z - d*P) = 4z - d*256`.

Per stage `t = 0..3`, start `inc = P` and divide `inc` by 4 each stage.
If mode predicate `f(ui_in, d, C)` holds, add `inc` to accumulator `Y`.

### Mode predicates (fabric, explicit `C`)

| `ui_in` | Mode | Accumulate when |
|---------|------|-----------------|
| `0010` | NOR | `d = 0` |
| `0000` | AND | `d = 3` (or `d = 2` if `C = 0`) |
| `0100` | XOR | `d` odd |
| `0101` | XNOR | `d` even |
| `0011` | OR | `d >= 1` (`C = 0`); else `d in {1,2,3}` |
| `0001` | NAND | complement of AND predicate |

Unary, pass-through, and constants: fabric delegates to cell oracle in Python;
Ngspice benches focus on logic modes `ui_in <= 5`.

## Cell oracle vs fabric

- **Cell** (`eval_cell`): mode table in `summary.md` — logic `0000..0101` is
  **digitwise on `A` and `B`**, masking deferred (no `C = 2222_4` in pass 1).
- **Fabric** (`eval_fabric`): residue on `z = A + B + C`.
- **Equivalence:** `fabric_matches_cell` is true for logic modes when `C = 0`;
  CSV column `fabric_eq_cell` marks comparable rows.

## Deferred to pass 2+

- `C = 2222_4` auto-mask ([`summary.md`](summary.md) section 4)
- Clocked residue / `rst_n` timing
- Multi-cell cascade
- AC settling and power rows from Q9 validation matrix

## Directory layout

| Path | Role |
|------|------|
| `asic/ngspice/` | SPICE decks (behavioural + sky130 sketch) |
| `asic/xschem/` | Schematic hierarchy notes |
| `asic/layout/` | Preliminary sky130 tile sketch |
| `asic/scripts/` | `run-sim.sh`, `check-vs-csv.py` |
| `data/kbee-base4-w4-refs.csv` | Golden vectors |
