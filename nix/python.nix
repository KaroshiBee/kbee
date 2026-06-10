# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
pkgs: let
  python = pkgs.python312.withPackages (ps:
    with ps; [
      numpy
      hypothesis
    ]);
  shellHook = ''
    export PYTHONUNBUFFERED=1
    export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
  '';
in {
  inherit python shellHook;
}
