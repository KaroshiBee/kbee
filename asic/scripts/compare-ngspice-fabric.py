#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Compare Ngspice fabric DC results to Python oracle for tb corners."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

import kbee as v  # noqa: E402

TB_DIR = REPO_ROOT / "asic/ngspice/tb"
NGSPICE = __import__("os").environ.get("NGSPICE", "ngspice")

CASES = [
    {"a": 85, "b": 0, "c": 0, "ui": 2},
    {"a": 5, "b": 10, "c": 0, "ui": 4},
    {"a": 3, "b": 3, "c": 3, "ui": 0},
]


def run_case(a: int, b: int, c: int, ui: int) -> float:
    deck = f"""
.include ../include/params.inc
.include ../fabric/reference_fabric.sp
.param a_code={a} b_code={b} c_code={c} ui_mode={ui}
Va Va 0 DC {{a_code}}
Vb Vb 0 DC {{b_code}}
Vc Vc 0 DC {{c_code}}
Xfab Vy Va Vb Vc kbee_reference_fabric ui_mode={ui}
.control
op
print V(Vy)
.endc
"""
    tmp = TB_DIR / "_tmp_compare.sp"
    tmp.write_text(deck, encoding="utf-8")
    out = subprocess.run(
        [NGSPICE, "-b", "_tmp_compare.sp"],
        cwd=TB_DIR,
        capture_output=True,
        text=True,
        check=False,
    )
    tmp.unlink(missing_ok=True)
    m = re.search(r"[vV]\(vy\)\s*=\s*([-0-9.eE+]+)", out.stdout + out.stderr)
    if not m:
        raise RuntimeError(f"no Vy in ngspice output:\n{out.stdout}\n{out.stderr}")
    return float(m.group(1))


def main() -> None:
    gates = v.Gates3InputsBase4.make4Bit()
    errors = 0
    for case in CASES:
        a, b, c, ui = case["a"], case["b"], case["c"], case["ui"]
        expected = gates.eval_fabric(ui, a, b, c)["y"]
        got_v = run_case(a, b, c, ui)
        got = int(round(got_v))
        if got != expected:
            errors += 1
            print(f"FAIL ui={ui} a={a} b={b} c={c}: spice Vy={got_v} oracle={expected}")
        else:
            print(f"ok ui={ui} a={a} b={b} c={c}: Vy={got}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
