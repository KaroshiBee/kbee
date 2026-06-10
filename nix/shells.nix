# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
{
  pkgs,
  fpgaPkgs,
  packages,
  pythonShellHook,
  python,
}: let
  inherit
    (packages)
    run-kbee-tests
    gen-kbee-refs
    gen-kbee-base4-w4-refs
    run-asic-sim
    check-asic-csv
    check-license-headers
    check-format-kbee
    check-kbee
    install-git-hooks
    format-kbee
    open-ad2
    iic-osic-tools
    ;
in {
  default = pkgs.mkShell {
    packages = with pkgs; [
      python
      run-kbee-tests
      gen-kbee-refs
      check-license-headers
      check-format-kbee
      check-kbee
      install-git-hooks
      format-kbee
      ripgrep
      fd
      fzf
      git
      bashInteractive
      coreutils
      gawk
      gnused
      lean4
    ];
    shellHook =
      pythonShellHook
      + ''
        echo "kbee devShell: oracle, proofs, format/check (see README.md)"
        echo "  nix develop .#fpaa  — Anadigm AD2 / fpaa scripts"
        echo "  nix develop .#asic  — Ngspice, xschem, sky130 sim"
        echo "  nix develop .#fpga  — HardCaml digital kbee"
      '';
  };

  fpaa = pkgs.mkShell {
    packages = with pkgs; [
      python
      open-ad2
      chmlib
      pandoc
      librsvg
      poppler-utils
      ripgrep
      git
      bashInteractive
      coreutils
    ];
    shellHook =
      pythonShellHook
      + ''
        echo "fpaa devShell: AD2 launcher + fpaa/ scripts (see fpaa/docs/)"
        echo "  open-ad2 fpaa/designs/kbee-04.ad2"
      '';
  };

  asic = pkgs.mkShell {
    packages = with pkgs; [
      python
      gen-kbee-base4-w4-refs
      run-asic-sim
      check-asic-csv
      ngspice
      xschem
      docker-client
      iic-osic-tools
      ripgrep
      git
      bashInteractive
      coreutils
    ];
    shellHook =
      pythonShellHook
      + ''
        export KBEE_ASIC_ROOT="$PWD/asic"
        export NGSPICE="${pkgs.ngspice}/bin/ngspice"
        export SKY130_PDK_HINT="iic-osic-tools or vendor open_pdks install"
        echo "asic devShell: Ngspice + xschem (see asic/README.md)"
      '';
  };

  fpga = fpgaPkgs.mkShell {
    packages = with fpgaPkgs; [
      ocamlPackages.ocaml
      ocamlPackages.dune_3
      ocamlPackages.merlin
      ocamlPackages.ocaml-lsp
      ocamlPackages.utop
      ocamlPackages.hardcaml
      ocamlPackages.ounit2
      ocamlformat
    ];
    shellHook = ''
      echo "fpga devShell: OCaml + Hardcaml overlay (see fpga/README.md)"
    '';
  };
}
