#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Validate kbee-04 NOR accumulator pulse/zero captures.

Expected channel map (default):
  Ch1: Load (NOR accumulator reset/run control)
  Ch2: oneOrTwo rail
  Ch3: isTwo rail
  Ch4: nor_hold.out (logical NOR accumulator state)

This checker assumes an exhaustive ascending code schedule (0000..2222 for W=4)
with one window per code. For each window it:
  1) decodes oneOrTwo/isTwo at configurable run-tick offsets
  2) compares rails to expected rails from the code's ternary digits
  3) compares measured nor_hold final code to expected NOR recurrence result
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


def parse_offsets(raw: str) -> list[float]:
    vals = [float(x.strip()) for x in raw.split(",") if x.strip()]
    if not vals:
        raise SystemExit("offset list cannot be empty")
    return vals


def base3(code: int, width: int) -> str:
    digits = []
    x = code
    for _ in range(width):
        digits.append(str(x % 3))
        x //= 3
    return "".join(reversed(digits))


def digits_msb_first(code: int, width: int) -> list[int]:
    return [int(ch) for ch in base3(code, width)]


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
    parser.add_argument("capture", type=Path, help="AD2 CSV capture")
    parser.add_argument(
        "--width", type=int, default=4, help="ternary width (default: 4)"
    )
    parser.add_argument(
        "--v-range",
        type=float,
        default=1.2,
        help="logical full-scale voltage (default: 1.2 V)",
    )
    parser.add_argument("--load-channel", type=int, choices=(1, 2, 3, 4), default=1)
    parser.add_argument("--oneortwo-channel", type=int, choices=(1, 2, 3, 4), default=2)
    parser.add_argument("--istwo-channel", type=int, choices=(1, 2, 3, 4), default=3)
    parser.add_argument("--norhold-channel", type=int, choices=(1, 2, 3, 4), default=4)
    parser.add_argument("--load-threshold-v", type=float, default=0.0)
    parser.add_argument("--rail-threshold-v", type=float, default=0.6)
    parser.add_argument(
        "--run-sample-offsets-us",
        default="16,24,32,36",
        help="run tick sample offsets from load rise (default: 16,24,32,36)",
    )
    parser.add_argument(
        "--final-offset-us",
        type=float,
        default=40.0,
        help="sample offset for final nor_hold code (default: 40)",
    )
    parser.add_argument(
        "--expected-windows",
        type=int,
        default=None,
        help="expected window count (default: 3**width)",
    )
    args = parser.parse_args()

    if args.width <= 0:
        raise SystemExit("--width must be > 0")
    if args.v_range <= 0:
        raise SystemExit("--v-range must be > 0")

    rows = load_rows(args.capture)
    times = [r[0] for r in rows]

    run_offsets_us = parse_offsets(args.run_sample_offsets_us)
    if len(run_offsets_us) != args.width:
        raise SystemExit(f"--run-sample-offsets-us must provide {args.width} offsets")

    code_count = 3**args.width
    expected_windows = (
        args.expected_windows if args.expected_windows is not None else code_count
    )

    rises = detect_load_rises(rows, args.load_channel, args.load_threshold_v)

    oo_idx = args.oneortwo_channel
    it_idx = args.istwo_channel
    nh_idx = args.norhold_channel
    v_unit = args.v_range / code_count

    rail_mismatches: list[str] = []
    final_mismatches: list[str] = []
    invalid_rail_pairs: list[str] = []

    full_windows = 0
    for win_i, t0 in enumerate(rises, start=1):
        code = (win_i - 1) % code_count
        digits = digits_msb_first(code, args.width)
        exp_oo = [1 if d >= 1 else 0 for d in digits]
        exp_it = [1 if d == 2 else 0 for d in digits]
        exp_nor = [1 if d == 0 else 0 for d in digits]

        got_oo: list[int] = []
        got_it: list[int] = []
        for dt_us in run_offsets_us:
            row = nearest_row(rows, times, t0 + dt_us * 1e-6)
            oo = 1 if row[oo_idx] > args.rail_threshold_v else 0
            it = 1 if row[it_idx] > args.rail_threshold_v else 0
            got_oo.append(oo)
            got_it.append(it)
            if it == 1 and oo == 0:
                invalid_rail_pairs.append(
                    f"win{win_i:03d} @{dt_us:g}us invalid rails (oneOrTwo,isTwo)=({oo},{it})"
                )

        if got_oo != exp_oo or got_it != exp_it:
            rail_mismatches.append(
                f"win{win_i:03d} code={base3(code, args.width)} "
                f"oo got={got_oo} exp={exp_oo} it got={got_it} exp={exp_it}"
            )

        t_final = t0 + args.final_offset_us * 1e-6
        if t_final <= rows[-1][0]:
            full_windows += 1
            row_f = nearest_row(rows, times, t_final)
            got_code = int(round(row_f[nh_idx] / v_unit))
            got_code = max(0, min(code_count - 1, got_code))
            exp_code = 0
            for b in exp_nor:
                exp_code = 3 * exp_code + b
            if got_code != exp_code:
                final_mismatches.append(
                    f"win{win_i:03d} code={base3(code, args.width)} "
                    f"nor_hold got={got_code} ({row_f[nh_idx]:.6f}V) exp={exp_code} ({exp_code * v_unit:.6f}V)"
                )

    print(f"file: {args.capture}")
    print(f"samples: {len(rows)}")
    print(f"t_end_us: {rows[-1][0] * 1e6:.1f}")
    print(f"load_rises: {len(rises)} (expected {expected_windows})")
    print(f"full_windows_for_final_check: {full_windows}")
    print(f"rail_mismatches: {len(rail_mismatches)}")
    print(f"invalid_rail_pairs(0,1): {len(invalid_rail_pairs)}")
    print(f"final_code_mismatches: {len(final_mismatches)}")

    if rail_mismatches:
        print("\nfirst rail mismatches:")
        for line in rail_mismatches[:10]:
            print("  -", line)

    if final_mismatches:
        print("\nfirst final-code mismatches:")
        for line in final_mismatches[:10]:
            print("  -", line)

    ok = (
        len(rises) == expected_windows
        and not rail_mismatches
        and not invalid_rail_pairs
        and not final_mismatches
    )
    if ok:
        print("\nPASS: capture matches NOR pulse/zero expectations")
        raise SystemExit(0)

    print("\nFAIL: capture does not match NOR pulse/zero expectations")
    raise SystemExit(2)


if __name__ == "__main__":
    main()
