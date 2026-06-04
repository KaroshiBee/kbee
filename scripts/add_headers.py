#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
"""Script to apply SPDX license identifiers and copyright notices to source files."""

import os
import subprocess


def get_comment_char(f):
    if f.endswith(".lean"):
        return "--"
    if f.endswith(".sp") or f.endswith(".inc"):
        return "*"
    if f.endswith("dune") or f.endswith("dune-project"):
        return ";"
    return "#"


def process(fpath, spdx_text, copyright_text):
    with open(fpath, "r") as f:
        content = f.read()

    char = get_comment_char(fpath)
    spdx_line = f"{char} {spdx_text}"
    copyright_line = f"{char} {copyright_text}"

    needs_spdx = spdx_text not in content
    needs_copyright = copyright_text not in content

    if not needs_spdx and not needs_copyright:
        return

    lines = content.split("\n")
    out = []

    has_shebang = len(lines) > 0 and lines[0].startswith("#!")

    if needs_spdx and needs_copyright:
        if has_shebang:
            out.append(lines[0])
            out.append(spdx_line)
            out.append(copyright_line)
            out.extend(lines[1:])
        else:
            out.append(spdx_line)
            out.append(copyright_line)
            out.extend(lines)
    elif needs_copyright and not needs_spdx:
        # Insert copyright immediately after SPDX
        for line in lines:
            out.append(line)
            if spdx_text in line:
                out.append(copyright_line)
    elif needs_spdx and not needs_copyright:
        # Insert SPDX immediately before copyright
        for line in lines:
            if copyright_text in line:
                out.append(spdx_line)
            out.append(line)

    with open(fpath, "w") as f:
        f.write("\n".join(out))


files = subprocess.check_output(["git", "ls-files"]).decode().split("\n")
for fpath in files:
    if not fpath:
        continue
    valid_exts = [".py", ".sh", ".lean", ".nix", ".sp", ".inc", ".scl"]
    if any(fpath.endswith(ext) for ext in valid_exts) or fpath in [
        "fpga/dune",
        "fpga/dune-project",
        ".envrc",
    ]:
        if "asic/ngspice" in fpath or fpath.endswith(".sp") or fpath.endswith(".inc"):
            spdx = "SPDX-License-Identifier: CERN-OHL-W-2.0-or-later"
        else:
            spdx = "SPDX-License-Identifier: LGPL-3.0-or-later"
        process(fpath, spdx, "Copyright (c) 2026 Karoshibee LTD")
