#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Cross-check Python oracle against CSV golden rows (sampled)."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

import kbee as v  # noqa: E402

CSV_PATH = REPO_ROOT / "data" / "kbee-base4-w4-refs.csv"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-rows", type=int, default=5000)
    parser.add_argument("--only-equiv", action="store_true")
    args = parser.parse_args()

    if not CSV_PATH.is_file():
        print(f"missing {CSV_PATH}; run gen-kbee-base4-w4-refs", file=sys.stderr)
        sys.exit(1)

    gates = v.Gates3InputsBase4.make4Bit()
    checked = 0
    errors = 0

    with CSV_PATH.open(newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if checked >= args.max_rows:
                break
            if args.only_equiv and int(row["fabric_eq_cell"]) == 0:
                continue
            ui = int(row["ui_in"])
            a = int(row["a_code"])
            b = int(row["b_code"])
            c = int(row["c_code"])
            y_cell = int(gates.eval_cell(ui, a, b, c)["y"])
            y_fab = int(gates.eval_fabric(ui, a, b, c)["y"])
            if y_cell != int(row["y_cell_code"]) or y_fab != int(row["y_fabric_code"]):
                errors += 1
                if errors <= 5:
                    print(
                        f"mismatch ui={ui} a={a} b={b} c={c}: "
                        f"csv cell={row['y_cell_code']} got={y_cell}"
                    )
            checked += 1

    print(f"checked {checked} rows, errors={errors}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
