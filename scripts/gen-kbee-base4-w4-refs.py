#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Generate base-4 W=4 ASIC reference CSV for Ngspice benches.

Enumerates (a_bin, b_bin, c_bin) in 0..15 and all ui_in modes 0..15.
Records cell oracle Y, fabric residue Y (when comparable), z trace, and
nominal/scaled currents.

Output: data/kbee-base4-w4-refs.csv (4096 * 16 = 65536 rows).

Usage:
    nix develop -c gen-kbee-base4-w4-refs
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "python"))

import kbee as v  # noqa: E402

W = 4
BASE = 4
N_W = BASE**W  # 256 code space
I_STEP_NOMINAL_A = 50e-9
K_SCALE_DEFAULT = 1.0


def code_to_I(code: int, k_scale: float = K_SCALE_DEFAULT) -> float:
    return code * I_STEP_NOMINAL_A * k_scale


def main() -> None:
    out_path = REPO_ROOT / "data" / "kbee-base4-w4-refs.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    gates = v.Gates3InputsBase4.make4Bit()

    header = [
        "a_bin",
        "b_bin",
        "c_bin",
        "a_code",
        "b_code",
        "c_code",
        "z_code",
        "ui_in",
        "y_cell_code",
        "y_fabric_code",
        "fabric_eq_cell",
        "digit_0",
        "digit_1",
        "digit_2",
        "digit_3",
        "z1_code",
        "z2_code",
        "z3_code",
        "z4_code",
        "a_I_nA",
        "b_I_nA",
        "c_I_nA",
        "z_I_nA",
        "y_cell_I_nA",
        "y_fabric_I_nA",
        "k_scale",
    ]

    mismatches = 0
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(header)

        for a_bin in range(16):
            a_code = int(v.Gates3InputsBase4.bin4_to_code(a_bin))
            for b_bin in range(16):
                b_code = int(v.Gates3InputsBase4.bin4_to_code(b_bin))
                for c_bin in range(16):
                    c_code = int(v.Gates3InputsBase4.bin4_to_code(c_bin))
                    z_code = a_code + b_code + c_code
                    trace = gates.residue_trace(a_code, b_code, c_code)

                    for ui_in in range(16):
                        cell = gates.eval_cell(ui_in, a_code, b_code, c_code)
                        fabric = gates.eval_fabric(ui_in, a_code, b_code, c_code)
                        y_cell = int(cell["y"])
                        y_fabric = int(fabric["y"])
                        eq = gates.fabric_matches_cell(ui_in, a_code, b_code, c_code)
                        if eq and y_cell != y_fabric:
                            mismatches += 1

                        row = [
                            a_bin,
                            b_bin,
                            c_bin,
                            a_code,
                            b_code,
                            c_code,
                            z_code,
                            ui_in,
                            y_cell,
                            y_fabric,
                            int(eq),
                            trace["digit_0"],
                            trace["digit_1"],
                            trace["digit_2"],
                            trace["digit_3"],
                            trace["z1"],
                            trace["z2"],
                            trace["z3"],
                            trace["z4"],
                            round(code_to_I(a_code) * 1e9, 3),
                            round(code_to_I(b_code) * 1e9, 3),
                            round(code_to_I(c_code) * 1e9, 3),
                            round(code_to_I(z_code) * 1e9, 3),
                            round(code_to_I(y_cell) * 1e9, 3),
                            round(code_to_I(y_fabric) * 1e9, 3),
                            K_SCALE_DEFAULT,
                        ]
                        writer.writerow(row)

    if mismatches:
        raise SystemExit(f"FATAL: {mismatches} fabric_eq_cell rows with y mismatch")

    print(
        f"wrote {16**3 * 16} rows -> {out_path} ({out_path.stat().st_size / 1024:.1f} KiB)"
    )


if __name__ == "__main__":
    main()
