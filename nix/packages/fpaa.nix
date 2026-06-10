# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
pkgs: {
  open-ad2 = pkgs.writeShellApplication {
    name = "open-ad2";
    runtimeInputs = with pkgs; [bash coreutils];
    text = ''
      set -euo pipefail

      FPAA_BIN="''${FPAA_BIN:-$(command -v fpaa 2>/dev/null || true)}"

      if [[ -z "$FPAA_BIN" || ! -x "$FPAA_BIN" ]]; then
        echo "error: fpaa launcher not found. Install AnadigmDesigner2 under Wine and" >&2
        echo "       ensure 'fpaa' is on PATH, or set FPAA_BIN to the launcher." >&2
        exit 1
      fi

      if [[ $# -eq 0 ]]; then
        exec "$FPAA_BIN"
      fi

      design="$1"
      if [[ ! -f "$design" ]]; then
        echo "error: design file not found: $design" >&2
        exit 1
      fi

      abs="$(readlink -f -- "$design")"
      win_path="Z:''${abs//\//\\}"

      exec "$FPAA_BIN" "$win_path"
    '';
  };
}
