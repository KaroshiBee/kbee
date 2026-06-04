# KBee cell — preliminary sky130 tile sketch (pass 1)

**Status:** area budget only; not tape-out ready. Sim signoff uses
pre-layout Ngspice (`asic/ngspice/`).

## Tile target

| Item | Value |
|------|-------|
| Shuttle context | Tiny Tapeout 2×2 mixed-signal tile |
| Reference area | 64,000 µm² ([`docs/summary.md`](../docs/summary.md) §6) |
| Utilisation goal | ~90% after rails |

## Block floorplan (rough)

```
+--------------------------------------------------+
|  bias / Iref                                     |
+----------+---------------+-----------+-----------+
| 3-in     | 4x residue    | mode acc  | 16:1 Y  |
| summer   | classify+shft | inject    | mux     |
| (~12%)   | (~38%)        | (~18%)    | (~12%)  |
+----------+---------------+-----------+-----------+
| routing / decap / ESD placeholder (~20%)         |
+--------------------------------------------------+
```

## Device sketch blocks

| Block | Schematic | sky130 sketch |
|-------|-----------|---------------|
| Summer | `leaves/summer.sp` | `ngspice/sky130/mos_mirror_min.sp` `i_summer3` |
| Classify | `leaves/comparator.sp` | diff pair + resistors (manual layout) |
| Residue ×4 | `leaves/residue_stage.sp` | current mirrors + switch array |
| Mux | `cell/kbee_cell.sp` | pass gates + analogue mux tree |

## Next layout steps (post pass-1 sim)

1. Import sky130 HD standard cells for digital `ui_in` pads only.
1. Place analogue core in enclosed dummies per MPW rules.
1. Extract with Magic/KLayout → post-layout Ngspice.
1. Compare extracted `Vy` to `data/kbee-base4-w4-refs.csv` (equiv rows).

## Area note

One residue stage + summer + mux at drawn W/L from `asic/data/params.scl`
is estimated **~28–35k µm²** analogue active (excluding pads), leaving margin
within 64k µm² before routing — consistent with summary §6 split.
