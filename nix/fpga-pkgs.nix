# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
{
  nixpkgs,
  ocaml-overlay,
  system,
}:
import nixpkgs {
  inherit system;
  overlays = [
    ocaml-overlay.overlays.default
    (import ../fpga/nix/overlay.nix)
    (_: prev: {
      # hardcaml 0.17.0 does not build against OCaml 5.4 parsetree yet
      ocamlPackages = prev.ocaml-ng.ocamlPackages_5_3;
    })
  ];
}
