#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Validate kbee-04 complement-pair captures (A + B = R_W * V_unit).

Default channel map:
  Ch1: load/control context (unused for metric)
  Ch2: classifier context (unused for metric)
  Ch3: branch A
  Ch4: branch B
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def load_rows(path: Path) -> list[tuple[float, float, float, float, float]]:
    rows: list[tuple[float, float, float, float, float]] = []
    with path.open() as f:
        reader = csv.reader(f, skipinitialspace=True)
        next(reader, None)
        for raw in reader:
            if not raw or not raw[0].strip():
                continue
            rows.append(tuple(float(x) for x in raw[:5]))
    if not rows:
        raise SystemExit(f"no samples found in {path}")
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path, help="AD2 CSV capture")
    parser.add_argument(
        "--width", type=int, default=4, help="ternary width used for expected R_W"
    )
    parser.add_argument(
        "--v-range", type=float, default=1.2, help="logical full-scale voltage"
    )
    parser.add_argument("--branch-a-channel", type=int, choices=(1, 2, 3, 4), default=3)
    parser.add_argument("--branch-b-channel", type=int, choices=(1, 2, 3, 4), default=4)
    parser.add_argument(
        "--start-us",
        type=float,
        default=0.0,
        help="ignore samples earlier than this time (us)",
    )
    parser.add_argument(
        "--abs-max-error-mv",
        type=float,
        default=0.5,
        help="pass threshold for max absolute error in mV",
    )
    args = parser.parse_args()

    if args.width <= 0:
        raise SystemExit("--width must be > 0")
    if args.v_range <= 0:
        raise SystemExit("--v-range must be > 0")
    if args.abs_max_error_mv < 0:
        raise SystemExit("--abs-max-error-mv must be >= 0")

    rows = load_rows(args.capture)
    start_s = args.start_us * 1e-6

    a_idx = args.branch_a_channel
    b_idx = args.branch_b_channel
    r_w = (3**args.width - 1) / 2
    target_v = r_w * (args.v_range / (3**args.width))

    errors_v: list[float] = []
    for row in rows:
        t_s = row[0]
        if t_s < start_s:
            continue
        errors_v.append((row[a_idx] + row[b_idx]) - target_v)

    if not errors_v:
        raise SystemExit("no samples left after --start-us filter")

    abs_errors_mv = [abs(e) * 1000.0 for e in errors_v]
    max_abs_mv = max(abs_errors_mv)
    mean_abs_mv = sum(abs_errors_mv) / len(abs_errors_mv)

    print(f"file: {args.capture}")
    print(f"samples_total: {len(rows)}")
    print(f"samples_used: {len(errors_v)}")
    print(f"target_v: {target_v:.7f} V")
    print(f"max_abs_error_mv: {max_abs_mv:.6f}")
    print(f"mean_abs_error_mv: {mean_abs_mv:.6f}")
    print(f"threshold_max_abs_mv: {args.abs_max_error_mv:.6f}")

    if max_abs_mv <= args.abs_max_error_mv:
        print("\nPASS: complement-pair invariant within threshold")
        raise SystemExit(0)

    print("\nFAIL: complement-pair invariant exceeds threshold")
    raise SystemExit(2)


if __name__ == "__main__":
    main()
