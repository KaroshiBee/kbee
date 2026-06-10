# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
{
  description = "KBee development environment";
  nixConfig.bash-prompt-suffix = "🐝 ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    with inputs;
      flake-utils.lib.eachDefaultSystem (
        system: let
          pkgs = import nixpkgs {inherit system;};
          pythonConfig = import ./nix/python.nix pkgs;
          packages = import ./nix/packages {
            pkgs = pkgs;
            python = pythonConfig.python;
          };
          fpgaPkgs = import ./nix/fpga-pkgs.nix {
            inherit nixpkgs ocaml-overlay system;
          };
          devShells = import ./nix/shells.nix {
            inherit pkgs fpgaPkgs packages;
            python = pythonConfig.python;
            pythonShellHook = pythonConfig.shellHook;
          };
        in {inherit devShells;}
      );
}
