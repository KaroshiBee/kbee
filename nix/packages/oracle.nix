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
  run-kbee-tests = pkgs.writeShellApplication {
    name = "run-kbee-tests";
    runtimeInputs = [python];
    text = ''
      ${pyPath}
      exec python -m unittest discover -s python/test -p 'test_*.py' "$@"
    '';
  };

  gen-kbee-refs = pkgs.writeShellApplication {
    name = "gen-kbee-refs";
    runtimeInputs = [python];
    text = ''
      ${pyPath}
      exec python scripts/gen-kbee-refs.py "$@"
    '';
  };

  gen-kbee-base4-w4-refs = pkgs.writeShellApplication {
    name = "gen-kbee-base4-w4-refs";
    runtimeInputs = [python];
    text = ''
      ${pyPath}
      exec python scripts/gen-kbee-base4-w4-refs.py "$@"
    '';
  };
}
