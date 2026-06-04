#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Generate z_sum and Load AWFs for arbitrary ternary pick sequences.

This is for residue bring-up runs where each active pick window can be followed
by an optional zeroing window to clear held rails between picks.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def emit_step(
    w: csv.writer, start_s: float, end_s: float, value: float, eps_s: float
) -> None:
    w.writerow([f"{start_s:.9f}", f"{value:.9f}"])
    w.writerow([f"{(end_s - eps_s):.9f}", f"{value:.9f}"])


def parse_ternary_codes(raw: str, width: int) -> list[int]:
    codes: list[int] = []
    for token in raw.split(","):
        s = token.strip()
        if not s:
            continue
        if any(ch not in "012" for ch in s):
            raise SystemExit(f"invalid ternary code '{s}' (digits must be 0/1/2)")
        if len(s) > width:
            raise SystemExit(f"ternary code '{s}' longer than width={width}")
        s = s.rjust(width, "0")
        codes.append(int(s, 3))
    if not codes:
        raise SystemExit("empty --codes")
    return codes


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--codes",
        default="0001,1111,2222",
        help="comma-separated ternary codes to run per active window",
    )
    parser.add_argument(
        "--width", type=int, default=4, help="ternary width (default: 4)"
    )
    parser.add_argument(
        "--v-range", type=float, default=1.2, help="z_sum full scale (default: 1.2 V)"
    )
    parser.add_argument(
        "--active-us",
        type=float,
        default=48.0,
        help="active window duration (default: 48 us)",
    )
    parser.add_argument(
        "--zero-us",
        type=float,
        default=48.0,
        help="zeroing window duration after each active window (default: 48 us; use 0 to disable)",
    )
    parser.add_argument(
        "--repeats", type=int, default=1, help="repeat full code sequence N times"
    )
    parser.add_argument(
        "--load-high-us",
        type=float,
        default=12.0,
        help="load HIGH width in each active window",
    )
    parser.add_argument(
        "--load-high-v", type=float, default=0.5, help="load HIGH level"
    )
    parser.add_argument("--load-low-v", type=float, default=-0.5, help="load LOW level")
    parser.add_argument(
        "--pulse-during-zero",
        action="store_true",
        help="also emit Load pulses during zero windows (default: disabled)",
    )
    parser.add_argument(
        "--out-base",
        default="zsum-pick-seq",
        help="basename for output files under data/waveforms",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=repo_root / "data" / "waveforms",
        help="output directory",
    )
    args = parser.parse_args()

    if args.width <= 0:
        raise SystemExit("--width must be > 0")
    if args.v_range <= 0:
        raise SystemExit("--v-range must be > 0")
    if args.active_us <= 0:
        raise SystemExit("--active-us must be > 0")
    if args.zero_us < 0:
        raise SystemExit("--zero-us must be >= 0")
    if args.repeats <= 0:
        raise SystemExit("--repeats must be > 0")
    if not (0 < args.load_high_us < args.active_us):
        raise SystemExit("--load-high-us must satisfy 0 < load_high_us < active_us")

    code_values = parse_ternary_codes(args.codes, args.width)
    code_count = 3**args.width
    den = float(code_count)
    active_s = args.active_us * 1e-6
    zero_s = args.zero_us * 1e-6
    load_hi_s = args.load_high_us * 1e-6
    eps_s = 1e-9

    args.out_dir.mkdir(parents=True, exist_ok=True)
    zsum_path = args.out_dir / f"{args.out_base}-zsum.csv"
    load_path = args.out_dir / f"{args.out_base}-load.csv"

    with open(zsum_path, "w", newline="") as fz, open(load_path, "w", newline="") as fl:
        wz = csv.writer(fz, lineterminator="\n")
        wl = csv.writer(fl, lineterminator="\n")
        t0 = 0.0

        for _ in range(args.repeats):
            for code in code_values:
                v = (code / den) * args.v_range
                emit_step(wz, t0, t0 + active_s, v, eps_s)
                emit_step(wl, t0, t0 + load_hi_s, args.load_high_v, eps_s)
                emit_step(wl, t0 + load_hi_s, t0 + active_s, args.load_low_v, eps_s)
                t0 += active_s

                if zero_s > 0:
                    emit_step(wz, t0, t0 + zero_s, 0.0, eps_s)
                    if args.pulse_during_zero:
                        emit_step(wl, t0, t0 + load_hi_s, args.load_high_v, eps_s)
                        emit_step(
                            wl, t0 + load_hi_s, t0 + zero_s, args.load_low_v, eps_s
                        )
                    else:
                        emit_step(wl, t0, t0 + zero_s, args.load_low_v, eps_s)
                    t0 += zero_s

    seq_ternary = ",".join(base3(c, args.width) for c in code_values)
    print(f"Wrote {zsum_path}")
    print(f"Wrote {load_path}")
    print(f"Codes: {seq_ternary}")
    print(
        f"Windows: active={args.active_us:g} us, zero={args.zero_us:g} us, repeats={args.repeats}"
    )


def base3(code: int, width: int) -> str:
    digits = []
    x = code
    for _ in range(width):
        digits.append(str(x % 3))
        x //= 3
    return "".join(reversed(digits))


if __name__ == "__main__":
    main()
