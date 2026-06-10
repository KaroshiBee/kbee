# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
{
  pkgs,
  python,
}: let
  pyPath = ''
    export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
  '';
in {
  run-asic-sim = pkgs.writeShellApplication {
    name = "run-asic-sim";
    runtimeInputs = with pkgs; [ngspice python];
    text = ''
      ${pyPath}
      exec bash asic/scripts/run-sim.sh "$@"
    '';
  };

  check-asic-csv = pkgs.writeShellApplication {
    name = "check-asic-csv";
    runtimeInputs = [python];
    text = ''
      ${pyPath}
      exec python asic/scripts/check-vs-csv.py "$@"
    '';
  };
}
