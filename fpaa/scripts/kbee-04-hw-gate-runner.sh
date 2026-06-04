#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
set -euo pipefail

# Run from any directory; resolves paths relative to the repo root.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPTS="$REPO_ROOT/fpaa/scripts"

usage() {
  echo "Usage:"
  echo "  $0 --residue <csv> --nor <csv> --nor-or <csv> --nand-and <csv> --xor-xnor <csv> [--out <logfile>]"
  exit 1
}

RESIDUE=""
NOR=""
NOR_OR=""
NAND_AND=""
XOR_XNOR=""
OUT_LOG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --residue)
               RESIDUE="${2:-}"
                                 shift 2
                                         ;;
    --nor)
           NOR="${2:-}"
                         shift 2
                                 ;;
    --nor-or)
              NOR_OR="${2:-}"
                               shift 2
                                       ;;
    --nand-and)
                NAND_AND="${2:-}"
                                   shift 2
                                           ;;
    --xor-xnor)
                XOR_XNOR="${2:-}"
                                   shift 2
                                           ;;
    --out)
           OUT_LOG="${2:-}"
                             shift 2
                                     ;;
    *) usage ;;
  esac
done

[[ -n "$RESIDUE" && -n "$NOR" && -n "$NOR_OR" && -n "$NAND_AND" && -n "$XOR_XNOR" ]] || usage

run() {
  echo
  echo "== $1 =="
  shift
  "$@"
}

if [[ -n "$OUT_LOG" ]]; then
  mkdir -p "$(dirname "$OUT_LOG")"
  exec > >(tee "$OUT_LOG") 2>&1
fi

echo "kbee-04 hardware gate runner"
echo "git_sha: $(git -C "$REPO_ROOT" rev-parse --short HEAD)"
echo "started_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

run "Residue 81-case gate" \
  python3 "$SCRIPTS/kbee-03-check-81-pulse-zero.py" \
    "$RESIDUE"

run "NOR accumulator 81-case gate" \
  python3 "$SCRIPTS/kbee-04-check-nor-pulse-zero.py" \
    "$NOR" \
    --run-sample-offsets-us 8,16,24,32 \
    --final-offset-us 42

run "NOR/OR invariant" \
  python3 "$SCRIPTS/kbee-04-check-complement-pair.py" \
    "$NOR_OR" \
    --start-us 40

run "NAND/AND invariant" \
  python3 "$SCRIPTS/kbee-04-check-complement-pair.py" \
    "$NAND_AND" \
    --start-us 40

run "XOR/XNOR invariant" \
  python3 "$SCRIPTS/kbee-04-check-complement-pair.py" \
    "$XOR_XNOR" \
    --start-us 40

echo
echo "ALL GATES PASS"
