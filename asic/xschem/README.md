# KBee ASIC Xschem hierarchy (pass 1)

Schematic capture mirrors `asic/ngspice/` hierarchy:

- `leaves/` — summer, classify, residue stage, DAC, encoder, sky130 mirror sketch
- `fabric/` — four-stage `reference_fabric`
- `cell/` — `kbee_cell` wrapper
- `layout/` — preliminary sky130 sketch (`kbee_tile.sky`)

Open with `nix develop -c xschem` from repo root. Netlists export to `asic/ngspice/` for Ngspice.
