#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Generate the kbee ground-truth reference CSV.

Exhaustively enumerates all (x, y) pairs where each is an 8-bit binary number
reinterpreted as an 8-digit base-3 number (digits constrained to {0, 1}).
For each pair, runs the reference ternary boolean algorithm from
python/kbee.py (Gates2Inputs(8).norandxor) and records:

  - x_bin, y_bin          : the binary-interpreted operand integers 0..255
  - x_code, y_code        : the base-3-interpreted operand integers 0..3280
  - z_code                : x_code + y_code, in 0..6560 (mod 3^8 no-op)
  - x_V, y_V, z_V         : corresponding voltages assuming V_range = 1.000 V
  - digit_0..digit_7      : leading base-3 digits of z processed tick-by-tick,
                            MSB first (digit_0 = d_7, digit_7 = d_0)
  - z1_code..z7_code      : post-tick residue integer codes (z_k with k in 1..7);
                            z_{k+1} = 3 * (z_k - digit_k * 3^7), all in 0..6560.
                            Useful for verifying the per-tick residue path.
  - z1_V..z7_V            : residue voltages for the above, at V_range = 1.000 V
  - nor_code, xor_code,
    and_code              : the three output integer codes 0..3280
  - nor_V, xor_V, and_V   : corresponding output voltages at V_range = 1.000 V

Intended consumers:
  - AD2 sim test benches (pick rows, set Signal Generator DC levels to {x,y}_V,
    compare scope reads against {nor,xor,and}_V)
  - Hardware sweep scripts (driving a real AN231K04 + scope)

Output: data/kbee-w8-refs.csv (65536 rows).

Usage:

    nix develop -c gen-kbee-refs
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "python"))

import numpy as np  # noqa: E402  (imported by kbee too)
import kbee as v  # noqa: E402

W = 8
BASE = 3
N = BASE**W  # 6561 — the mod base, and the number of addressable levels
V_RANGE = 1.0  # volts; matches plan §1. Change here if the design scales up.


def digits_msb(n: int, base: int, width: int) -> list[int]:
    """Base-`base` digits of `n`, MSB first, padded on the left to `width`."""
    return [int(d) for d in v.to_baseN(int(n), base, width)]


def code_to_bin(code: int) -> int:
    """Interpret the base-3 code (digits in {0, 1}) as an 8-bit binary int."""
    out = 0
    for d in digits_msb(code, 3, W):
        out = (out << 1) | d
    return out


def main() -> None:
    out_path = REPO_ROOT / "data" / "kbee-w8-refs.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    gates = v.Gates2Inputs(W)

    three_W_minus_1 = BASE ** (W - 1)  # 3^7 = 2187, the MSB-digit weight
    header = (
        ["x_bin", "y_bin", "x_code", "y_code", "z_code", "x_V", "y_V", "z_V"]
        + [f"digit_{k}" for k in range(W)]
        + [f"z{k}_code" for k in range(1, W)]
        + [f"z{k}_V" for k in range(1, W)]
        + ["nor_code", "xor_code", "and_code", "nor_V", "xor_V", "and_V"]
    )

    mismatches = 0

    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(header)

        for x_bin in range(256):
            x_code = int(v.from_base3(v.to_baseN(x_bin, 2, W)))
            for y_bin in range(256):
                y_code = int(v.from_base3(v.to_baseN(y_bin, 2, W)))
                z_code = x_code + y_code

                result = gates.norandxor(x_code, y_code)
                nor_code = int(result["nor"][0])
                xor_code = int(result["xor"][0])
                and_code = int(result["and"][0])

                z_digits = digits_msb(z_code, 3, W)

                # Per-tick residue trace: mirror the algorithm in plan §1 so the
                # CSV lets AD2 test benches check the residue-path CAMs at any
                # tick without re-deriving the recurrence by hand.
                residues: list[int] = []
                z_curr = z_code
                for k in range(W):
                    d_k = z_digits[k]
                    z_next = 3 * (z_curr - d_k * three_W_minus_1)
                    if k < W - 1:
                        residues.append(z_next)
                    z_curr = z_next
                # After the last tick residues should be 0 (the all-digits-extracted
                # boundary); we don't need to emit it but we assert it.
                assert z_curr == 0, (
                    f"residue trace did not terminate at 0 for "
                    f"(x_bin={x_bin}, y_bin={y_bin}): last z_curr={z_curr}"
                )

                # Cross-check reference against plain binary truth; any drift here
                # would mean the kbee model disagrees with itself and we should
                # stop before feeding garbage into AD2.
                if (
                    code_to_bin(nor_code) != ((~(x_bin | y_bin)) & 0xFF)
                    or code_to_bin(xor_code) != (x_bin ^ y_bin) & 0xFF
                    or code_to_bin(and_code) != (x_bin & y_bin) & 0xFF
                ):
                    mismatches += 1

                row = (
                    [
                        x_bin,
                        y_bin,
                        x_code,
                        y_code,
                        z_code,
                        round(x_code / N * V_RANGE, 6),
                        round(y_code / N * V_RANGE, 6),
                        round(z_code / N * V_RANGE, 6),
                    ]
                    + z_digits
                    + residues
                    + [round(r / N * V_RANGE, 6) for r in residues]
                    + [
                        nor_code,
                        xor_code,
                        and_code,
                        round(nor_code / N * V_RANGE, 6),
                        round(xor_code / N * V_RANGE, 6),
                        round(and_code / N * V_RANGE, 6),
                    ]
                )
                writer.writerow(row)

    if mismatches:
        raise SystemExit(f"FATAL: {mismatches} rows disagreed with plain binary logic")

    n_rows = 256 * 256
    size_bytes = out_path.stat().st_size
    print(f"wrote {n_rows} rows -> {out_path} ({size_bytes / 1024:.1f} KiB)")

    # Print a handful of corner rows so the CSV is self-documenting when read
    # from a terminal.
    corners = [(0, 0), (0, 255), (255, 0), (255, 255), (85, 170), (170, 85)]
    print("\ncorner rows (x_bin, y_bin) -> (z_code, nor_code, xor_code, and_code):")
    for xb, yb in corners:
        xc = int(v.from_base3(v.to_baseN(xb, 2, W)))
        yc = int(v.from_base3(v.to_baseN(yb, 2, W)))
        r = gates.norandxor(xc, yc)
        print(
            f"  ({xb:3d}, {yb:3d}) -> "
            f"z={xc + yc:5d}, "
            f"nor={int(r['nor'][0]):5d}, "
            f"xor={int(r['xor'][0]):5d}, "
            f"and={int(r['and'][0]):5d}"
        )


if __name__ == "__main__":
    main()
