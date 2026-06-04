#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Generate canonical 4-trit exhaustive pulse/zero residue waveforms.

This emits the active test set used for residue validation:
  - zsum-4trit-81-1x-A32-B8-v1p2-x.csv
  - zsum-4trit-81-1x-A32-B8-v1p2-y.csv
  - zsum-4trit-81-1x-A32-B8-v1p2-load.csv

`x` and `y` are generated so that `x + y` equals the original `z_sum`
target at every active window.
"""

from __future__ import annotations

import csv
from pathlib import Path


def emit_step(
    writer: csv.writer, start_s: float, end_s: float, value: float, eps_s: float
) -> None:
    writer.writerow([f"{start_s:.9f}", f"{value:.9f}"])
    writer.writerow([f"{(end_s - eps_s):.9f}", f"{value:.9f}"])


def base3(code: int, width: int) -> str:
    digits = []
    x = code
    for _ in range(width):
        digits.append(str(x % 3))
        x //= 3
    return "".join(reversed(digits))


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    out_dir = repo_root / "data" / "waveforms"
    out_dir.mkdir(parents=True, exist_ok=True)

    x_path = out_dir / "zsum-4trit-81-1x-A32-B8-v1p2-x.csv"
    y_path = out_dir / "zsum-4trit-81-1x-A32-B8-v1p2-y.csv"
    load_path = out_dir / "zsum-4trit-81-1x-A32-B8-v1p2-load.csv"

    width = 4
    code_count = 3**width
    den = float(code_count)
    v_range = 1.2

    active_s = 32e-6
    zero_s = 8e-6
    load_hi_s = 8e-6
    load_high_v = 0.5
    load_low_v = -0.5
    eps_s = 1e-9

    with (
        open(x_path, "w", newline="") as fx,
        open(y_path, "w", newline="") as fy,
        open(load_path, "w", newline="") as fl,
    ):
        wx = csv.writer(fx, lineterminator="\n")
        wy = csv.writer(fy, lineterminator="\n")
        wl = csv.writer(fl, lineterminator="\n")
        t0 = 0.0

        for code in range(code_count):
            z_target_v = (code / den) * v_range
            # Symmetric split keeps both inputs in-range while preserving x+y=z.
            x_v = z_target_v / 2.0
            y_v = z_target_v / 2.0
            emit_step(wx, t0, t0 + active_s, x_v, eps_s)
            emit_step(wy, t0, t0 + active_s, y_v, eps_s)
            emit_step(wl, t0, t0 + load_hi_s, load_high_v, eps_s)
            emit_step(wl, t0 + load_hi_s, t0 + active_s, load_low_v, eps_s)
            t0 += active_s

            emit_step(wx, t0, t0 + zero_s, 0.0, eps_s)
            emit_step(wy, t0, t0 + zero_s, 0.0, eps_s)
            emit_step(wl, t0, t0 + zero_s, load_low_v, eps_s)
            t0 += zero_s

    print(f"Wrote {x_path}")
    print(f"Wrote {y_path}")
    print(f"Wrote {load_path}")
    print(
        f"Codes: {base3(0, width)}..{base3(code_count - 1, width)} ({code_count} total)"
    )
    print("Windows: active=32 us, zero=8 us, repeats=1")
    print("Split strategy: x = y = z_sum / 2 (so x+y reproduces the canonical z_sum)")
    print("Total sim time: 3.24 ms")


if __name__ == "__main__":
    main()
