#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
# Run Ngspice benches under asic/ngspice/tb/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NGSPICE="${NGSPICE:-ngspice}"
TB_DIR="$ROOT/asic/ngspice/tb"
OUT_DIR="$ROOT/asic/ngspice/out"

mkdir -p "$OUT_DIR"

run_one() {
  local deck="$1"
  local name
  name="$(basename "$deck" .sp)"
  echo "==> $name"
  (cd "$TB_DIR" && "$NGSPICE" -b "$deck") | tee "$OUT_DIR/${name}.log"
}

if [ "$#" -gt 0 ]; then
  for deck in "$@"; do
    run_one "$deck"
  done
else
  for deck in "$TB_DIR"/*.sp; do
    run_one "$deck"
  done
fi

echo "logs in $OUT_DIR"
