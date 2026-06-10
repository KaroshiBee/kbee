# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
{
  pkgs,
  python,
}: let
  oracle = import ./oracle.nix {inherit pkgs python;};
  asic = import ./asic.nix {inherit pkgs python;};
  fpaa = import ./fpaa.nix pkgs;
  checks = import ./checks.nix pkgs;
  iic-osic-tools = import ./iic-osic-tools.nix pkgs;
in
  oracle
  // asic
  // fpaa
  // checks
  // {inherit iic-osic-tools;}
