#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Validate an exhaustive 4-trit pulse/zero residue capture in one command.

Checks performed:
  1) Detect load-pulse windows and ensure count matches 3**width (default 81).
  2) Decode seed code from z-hold at +8 us and verify strict 0000..2222 order.
  3) Verify one-step delayed classifier behavior within each window:
       rails(t[k+1]) == threshold_bits(z_hold(t[k])).
  4) Verify delayed continuity across window boundaries.
"""

from __future__ import annotations

import argparse
import bisect
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


def nearest_row(
    rows: list[tuple[float, float, float, float, float]],
    times: list[float],
    t_s: float,
) -> tuple[float, float, float, float, float]:
    i = bisect.bisect_left(times, t_s)
    candidates: list[tuple[float, float, float, float, float]] = []
    if i < len(rows):
        candidates.append(rows[i])
    if i > 0:
        candidates.append(rows[i - 1])
    return min(candidates, key=lambda r: abs(r[0] - t_s))


def base3(code: int, width: int) -> str:
    digits = []
    x = code
    for _ in range(width):
        digits.append(str(x % 3))
        x //= 3
    return "".join(reversed(digits))


def parse_checkpoints(raw: str) -> list[float]:
    vals = [float(x.strip()) for x in raw.split(",") if x.strip()]
    if len(vals) < 2:
        raise SystemExit("--checkpoints-us must contain at least two values")
    return vals


def detect_load_rises(
    rows: list[tuple[float, float, float, float, float]],
    load_channel: int,
    threshold_v: float,
) -> list[float]:
    idx = load_channel
    rises: list[float] = []
    if rows[0][idx] > threshold_v:
        rises.append(rows[0][0])
    for i in range(1, len(rows)):
        if rows[i - 1][idx] <= threshold_v and rows[i][idx] > threshold_v:
            rises.append(rows[i][0])
    return rises


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path, help="AD2 CSV capture to validate")
    parser.add_argument(
        "--width", type=int, default=4, help="ternary width (default: 4)"
    )
    parser.add_argument(
        "--v-range",
        type=float,
        default=1.2,
        help="z_hold full-scale range (default: 1.2 V)",
    )
    parser.add_argument("--load-channel", type=int, choices=(1, 2, 3, 4), default=1)
    parser.add_argument("--oneortwo-channel", type=int, choices=(1, 2, 3, 4), default=2)
    parser.add_argument("--istwo-channel", type=int, choices=(1, 2, 3, 4), default=3)
    parser.add_argument("--zhold-channel", type=int, choices=(1, 2, 3, 4), default=4)
    parser.add_argument(
        "--load-threshold-v",
        type=float,
        default=0.0,
        help="rising-edge threshold for load pulse detection",
    )
    parser.add_argument(
        "--rail-high-threshold-v",
        type=float,
        default=0.6,
        help="decode threshold for measured classifier rails",
    )
    parser.add_argument(
        "--thr-one-v",
        type=float,
        default=0.398,
        help="oneOrTwo logical threshold for z_hold-derived expected rails",
    )
    parser.add_argument(
        "--thr-two-v",
        type=float,
        default=0.798,
        help="isTwo logical threshold for z_hold-derived expected rails",
    )
    parser.add_argument(
        "--seed-offset-us",
        type=float,
        default=8.0,
        help="offset from load-rise to decode seed z_hold code",
    )
    parser.add_argument(
        "--checkpoints-us",
        default="8,20,32,44,56",
        help="comma-separated checkpoint offsets for delayed-rail checks (default: 8,20,32,44,56)",
    )
    args = parser.parse_args()

    if args.width <= 0:
        raise SystemExit("--width must be > 0")
    if args.v_range <= 0:
        raise SystemExit("--v-range must be > 0")

    rows = load_rows(args.capture)
    times = [r[0] for r in rows]
    checkpoints_us = parse_checkpoints(args.checkpoints_us)
    checkpoints_s = [t * 1e-6 for t in checkpoints_us]

    rises = detect_load_rises(rows, args.load_channel, args.load_threshold_v)
    expected_windows = 3**args.width

    z_idx = args.zhold_channel
    oo_idx = args.oneortwo_channel
    it_idx = args.istwo_channel

    def seed_code_from_z(v: float) -> int:
        den = float(3**args.width)
        code = round((v / args.v_range) * den)
        return max(0, min(int(den) - 1, int(code)))

    def rails_from_measurement(
        row: tuple[float, float, float, float, float],
    ) -> tuple[int, int]:
        return (
            1 if row[oo_idx] > args.rail_high_threshold_v else 0,
            1 if row[it_idx] > args.rail_high_threshold_v else 0,
        )

    def rails_from_z(v: float) -> tuple[int, int]:
        return (
            1 if v > args.thr_one_v else 0,
            1 if v > args.thr_two_v else 0,
        )

    seed_codes: list[int] = []
    for t0 in rises:
        row = nearest_row(rows, times, t0 + args.seed_offset_us * 1e-6)
        seed_codes.append(seed_code_from_z(row[z_idx]))

    expected_seed_codes = list(range(expected_windows))
    seed_sequence_ok = seed_codes == expected_seed_codes

    in_window_mismatches: list[str] = []
    for win_i, t0 in enumerate(rises, start=1):
        z_by_cp: list[float] = []
        rails_by_cp: list[tuple[int, int]] = []
        for dt_s in checkpoints_s:
            row = nearest_row(rows, times, t0 + dt_s)
            z_by_cp.append(row[z_idx])
            rails_by_cp.append(rails_from_measurement(row))
        for k in range(len(checkpoints_s) - 1):
            exp = rails_from_z(z_by_cp[k])
            got = rails_by_cp[k + 1]
            if got != exp:
                in_window_mismatches.append(
                    f"win{win_i:02d} +{checkpoints_us[k + 1]:g}us got={got} exp={exp} "
                    f"(from z@+{checkpoints_us[k]:g}us={z_by_cp[k]:.6f})"
                )

    cross_window_mismatches: list[str] = []
    for i in range(1, len(rises)):
        prev_last = nearest_row(rows, times, rises[i - 1] + checkpoints_s[-1])
        this_first = nearest_row(rows, times, rises[i] + checkpoints_s[0])
        exp = rails_from_z(prev_last[z_idx])
        got = rails_from_measurement(this_first)
        if got != exp:
            cross_window_mismatches.append(
                f"win{i + 1:02d} +{checkpoints_us[0]:g}us got={got} exp={exp} "
                f"(from prev z@+{checkpoints_us[-1]:g}us={prev_last[z_idx]:.6f})"
            )

    print(f"file: {args.capture}")
    print(f"samples: {len(rows)}")
    print(f"t_end_us: {rows[-1][0] * 1e6:.1f}")
    print(f"load_rises: {len(rises)} (expected {expected_windows})")
    print("seed_first10: " + ",".join(base3(c, args.width) for c in seed_codes[:10]))
    print("seed_last10:  " + ",".join(base3(c, args.width) for c in seed_codes[-10:]))
    print(f"seed_sequence_ok: {seed_sequence_ok}")
    print(
        f"in_window_checks: {max(0, len(rises)) * (len(checkpoints_s) - 1)} "
        f"mismatches={len(in_window_mismatches)}"
    )
    print(
        f"cross_window_checks: {max(0, len(rises) - 1)} "
        f"mismatches={len(cross_window_mismatches)}"
    )

    if in_window_mismatches:
        print("\nfirst in-window mismatches:")
        for line in in_window_mismatches[:8]:
            print("  -", line)
    if cross_window_mismatches:
        print("\nfirst cross-window mismatches:")
        for line in cross_window_mismatches[:8]:
            print("  -", line)

    ok = (
        len(rises) == expected_windows
        and seed_sequence_ok
        and not in_window_mismatches
        and not cross_window_mismatches
    )
    if ok:
        print("\nPASS: capture matches exhaustive 81-case pulse/zero expectations")
        raise SystemExit(0)

    print("\nFAIL: capture does not match exhaustive pulse/zero expectations")
    raise SystemExit(2)


if __name__ == "__main__":
    main()
