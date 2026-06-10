# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
final: prev:
with prev; let
  inherit (ocaml-ng) ocamlPackages_5_3;
in {
  ocaml-ng =
    ocaml-ng
    // {
      ocamlPackages_5_3 = ocamlPackages_5_3.overrideScope (_: lp:
        with lp; {
          hardcaml = buildDunePackage rec {
            pname = "hardcaml";
            version = "0.17.0";
            src = fetchFromGitHub {
              owner = "janestreet";
              repo = "hardcaml";
              rev = "c5ec6979742d7f9a750c9e946de5ffa62f890be2";
              hash = "sha256-lRzqXuUYrk3VjQhFDTN0Q/aPolf0gKr4gK0i1ZOKKww=";
            };
            postPatch = ''
                    substituteInPlace ppx/src/ppx_hardcaml_zero.ml \
                      --replace '; pvb_loc' '; pvb_loc
              ; pvb_constraint = None'
            '';
            propagatedBuildInputs = [
              base
              bignum
              bin_prot
              core_kernel
              jane_rope
              ppx_jane
              ppx_sexp_conv
              sexplib
              splittable_random
              stdio
              dune
              ppxlib
            ];
          };
        });
    };
}
