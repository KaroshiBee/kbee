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
          python = pkgs.python312.withPackages (ps:
            with ps; [
              numpy
              hypothesis
            ]);

          fpgaPkgs = import nixpkgs {
            inherit system;
            overlays = [
              ocaml-overlay.overlays.default
              (import ./fpga/nix/overlay.nix)
              (_: prev: {
                # hardcaml 0.17.0 does not build against OCaml 5.4 parsetree yet
                ocamlPackages = prev.ocaml-ng.ocamlPackages_5_3;
              })
            ];
          };

          iic-osic-tools = pkgs.writeShellApplication {
            name = "iic-osic-tools";
            runtimeInputs = with pkgs; [
              coreutils
              docker-client
            ];
            text = ''
              set -euo pipefail

              if ! command -v docker >/dev/null 2>&1; then
                echo "error: docker not found in PATH." >&2
                exit 1
              fi

              image="''${IIC_OSIC_TOOLS_IMAGE:-hpretl/iic-osic-tools:latest}"
              workdir="''${IIC_OSIC_WORKDIR:-/foss/designs}"
              use_skip=1
              ui_local=0
              ui_http_port="''${IIC_OSIC_UI_HTTP_PORT:-6080}"
              ui_vnc_port="''${IIC_OSIC_UI_VNC_PORT:-5901}"

              while [ "$#" -gt 0 ]; do
                case "$1" in
                  --ui)
                    use_skip=0
                    shift
                    ;;
                  --ui-local)
                    use_skip=0
                    ui_local=1
                    shift
                    ;;
                  --)
                    shift
                    break
                    ;;
                  *)
                    break
                    ;;
                esac
              done

              if [ "$#" -eq 0 ]; then
                set -- bash
              fi

              docker_args=(
                run
                --rm
                -u "$(id -u):$(id -g)"
                -v "$PWD:$workdir"
                -w "$workdir"
              )

              if [ -t 0 ] && [ -t 1 ]; then
                docker_args+=(-it)
              elif [ -t 0 ]; then
                docker_args+=(-i)
              fi

              if [ "$ui_local" -eq 1 ]; then
                docker_args+=(
                  -p "127.0.0.1:$ui_http_port:80"
                  -p "127.0.0.1:$ui_vnc_port:5901"
                )
                echo "iic-osic-tools UI URL: http://localhost:$ui_http_port/vnc.html?password=abc123" >&2
              fi

              if [ "$use_skip" -eq 1 ]; then
                exec docker "''${docker_args[@]}" "$image" --skip "$@"
              fi

              exec docker "''${docker_args[@]}" "$image" "$@"
            '';
          };

          pythonShellHook = ''
            export PYTHONUNBUFFERED=1
            export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
          '';

          run-kbee-tests = pkgs.writeShellApplication {
            name = "run-kbee-tests";
            runtimeInputs = [python];
            text = ''
              export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
              exec python -m unittest discover -s python/test -p 'test_*.py' "$@"
            '';
          };

          gen-kbee-refs = pkgs.writeShellApplication {
            name = "gen-kbee-refs";
            runtimeInputs = [python];
            text = ''
              export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
              exec python scripts/gen-kbee-refs.py "$@"
            '';
          };

          gen-kbee-base4-w4-refs = pkgs.writeShellApplication {
            name = "gen-kbee-base4-w4-refs";
            runtimeInputs = [python];
            text = ''
              export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
              exec python scripts/gen-kbee-base4-w4-refs.py "$@"
            '';
          };

          run-asic-sim = pkgs.writeShellApplication {
            name = "run-asic-sim";
            runtimeInputs = with pkgs; [ngspice python];
            text = ''
              export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
              exec bash asic/scripts/run-sim.sh "$@"
            '';
          };

          check-asic-csv = pkgs.writeShellApplication {
            name = "check-asic-csv";
            runtimeInputs = [python];
            text = ''
              export PYTHONPATH="$PWD/python''${PYTHONPATH:+:$PYTHONPATH}"
              exec python asic/scripts/check-vs-csv.py "$@"
            '';
          };

          format-kbee = pkgs.writeShellApplication {
            name = "format-kbee";
            runtimeInputs = with pkgs; [
              bash
              git
              coreutils
              ruff
              shfmt
              alejandra
              mdformat
              taplo
            ];
            text = ''
              set -euo pipefail

              ROOT="$(git rev-parse --show-toplevel)"
              cd "$ROOT"

              # Format tracked sources in place. Skips generated/binary artefacts
              # (CSV, Spice, .ad2, images, flake.lock, lake-manifest.json, …).

              py_files="$(git ls-files '*.py' || true)"
              if [ -n "$py_files" ]; then
                echo "==> Python (ruff format)"
                xargs -r ruff format <<< "$py_files"
              fi

              sh_files="$(git ls-files '*.sh' || true)"
              if [ -n "$sh_files" ]; then
                echo "==> Shell (shfmt)"
                xargs -r shfmt -w -i 2 -ci -bn -sr -kp <<< "$sh_files"
              fi

              nix_files="$(git ls-files '*.nix' || true)"
              if [ -n "$nix_files" ]; then
                echo "==> Nix (alejandra)"
                xargs -r alejandra <<< "$nix_files"
              fi

              md_files="$(git ls-files '*.md' || true)"
              if [ -n "$md_files" ]; then
                echo "==> Markdown (mdformat)"
                xargs -r mdformat <<< "$md_files"
              fi

              toml_files="$(git ls-files '*.toml' || true)"
              if [ -n "$toml_files" ]; then
                echo "==> TOML (taplo)"
                xargs -r taplo format <<< "$toml_files"
              fi

              yaml_files="$(git ls-files '*.yaml' '*.yml' || true)"
              if [ -n "$yaml_files" ]; then
                echo "==> YAML (taplo)"
                xargs -r taplo format <<< "$yaml_files"
              fi

              lean_files="$(git ls-files 'proofs/**/*.lean' || true)"
              if [ -n "$lean_files" ]; then
                echo "==> Lean (skipped)"
                echo "    no CLI formatter in Lean 4.29 / Lake 5 — use editor format-on-save"
              fi

              echo ""
              echo "Skipped: .csv (generated), .sp/.inc, .lean (no CLI fmt), .ad2, images"
              echo ""
              echo "format-kbee: OK"
            '';
          };

          check-format-kbee = pkgs.writeShellApplication {
            name = "check-format-kbee";
            runtimeInputs = with pkgs; [
              bash
              git
              coreutils
              ruff
              shfmt
              alejandra
              mdformat
              taplo
            ];
            text = ''
              set -euo pipefail

              ROOT="$(git rev-parse --show-toplevel)"
              workdir=""
              cleanup() {
                if [ -n "$workdir" ] && [ -d "$workdir" ]; then
                  rm -rf "$workdir"
                fi
              }
              trap cleanup EXIT

              if [ -n "''${KBEE_CHECK_REV:-}" ]; then
                echo "check-format-kbee: tree ''${KBEE_CHECK_REV}"
                workdir="$(mktemp -d)"
                git -C "$ROOT" archive "''${KBEE_CHECK_REV}" | tar -x -C "$workdir"
                cd "$workdir"
              else
                echo "check-format-kbee: working tree"
                cd "$ROOT"
              fi

              fail=0

              list_glob() {
                find . -type f -name "$1" ! -path './proofs/.lake/*' \
                  ! -path './.hypothesis/*' ! -path './.direnv/*' \
                  | sed 's|^\./||' | sort
              }

              py_files="$(list_glob '*.py' || true)"
              if [ -n "$py_files" ]; then
                echo "==> Python (ruff format --check)"
                if ! xargs -r ruff format --check <<< "$py_files"; then
                  fail=1
                fi
              fi

              sh_files="$(list_glob '*.sh' || true)"
              if [ -n "$sh_files" ]; then
                echo "==> Shell (shfmt -d)"
                if ! xargs -r shfmt -d -i 2 -ci -bn -sr -kp <<< "$sh_files"; then
                  fail=1
                fi
              fi

              nix_files="$(list_glob '*.nix' || true)"
              if [ -n "$nix_files" ]; then
                echo "==> Nix (alejandra --check)"
                if ! xargs -r alejandra --check <<< "$nix_files"; then
                  fail=1
                fi
              fi

              md_files="$(list_glob '*.md' || true)"
              if [ -n "$md_files" ]; then
                echo "==> Markdown (mdformat --check)"
                if ! xargs -r mdformat --check <<< "$md_files"; then
                  fail=1
                fi
              fi

              toml_files="$(list_glob '*.toml' || true)"
              if [ -n "$toml_files" ]; then
                echo "==> TOML (taplo format --check)"
                if ! xargs -r taplo format --check <<< "$toml_files"; then
                  fail=1
                fi
              fi

              yaml_files="$(find . -type f \( -name '*.yaml' -o -name '*.yml' \) \
                ! -path './proofs/.lake/*' | sed 's|^\./||' | sort || true)"
              if [ -n "$yaml_files" ]; then
                echo "==> YAML (taplo format --check)"
                if ! xargs -r taplo format --check <<< "$yaml_files"; then
                  fail=1
                fi
              fi

              if (( fail )); then
                echo ""
                echo "check-format-kbee: FAILED (run: nix develop -c format-kbee)" >&2
                exit 1
              fi

              echo ""
              echo "check-format-kbee: OK"
            '';
          };

          check-license-headers = pkgs.writeShellApplication {
            name = "check-license-headers";
            runtimeInputs = with pkgs; [bash git ripgrep coreutils];
            text = ''
              set -euo pipefail

              ROOT="$(git rev-parse --show-toplevel)"
              workdir=""
              cleanup() {
                if [ -n "$workdir" ] && [ -d "$workdir" ]; then
                  rm -rf "$workdir"
                fi
              }
              trap cleanup EXIT

              if [ -n "''${KBEE_CHECK_REV:-}" ]; then
                echo "check-license-headers: tree ''${KBEE_CHECK_REV}"
                workdir="$(mktemp -d)"
                git -C "$ROOT" archive "''${KBEE_CHECK_REV}" | tar -x -C "$workdir"
                cd "$workdir"
              else
                echo "check-license-headers: working tree"
                cd "$ROOT"
              fi

              HEADER_PATTERN='SPDX-License-Identifier|Copyright'
              RG_SKIP=(
                --glob '!proofs/.lake/**'
                --glob '!.hypothesis/**'
                --glob '!.direnv/**'
              )

              fail=0

              echo "==> rg --files-without-match (.py / .sh, skip proofs/.lake)"
              missing_rg=()
              while IFS= read -r f; do
                missing_rg+=("$f")
              done < <(
                rg --files-without-match "$HEADER_PATTERN" \
                  --glob '*.py' --glob '*.sh' \
                  "''${RG_SKIP[@]}" . || true
              )
              if ((''${#missing_rg[@]})); then
                printf 'MISSING (rg): %s\n' "''${missing_rg[@]}"
                fail=1
              else
                echo "ok — all .py/.sh have SPDX or Copyright"
              fi

              echo ""
              echo "==> header check (.py / .sh / .nix / .lean)"
              missing_git=()
              total_git=0
              while IFS= read -r f; do
                total_git=$((total_git + 1))
                if ! head -5 "$f" | grep -q Copyright; then
                  missing_git+=("$f")
                fi
              done < <(
                find . -type f \( -name '*.py' -o -name '*.sh' -o -name '*.nix' -o -name '*.lean' \) \
                  ! -path './proofs/.lake/*' | sed 's|^\./||' | sort
              )
              if ((''${#missing_git[@]})); then
                printf 'MISSING (git): %s\n' "''${missing_git[@]}"
                fail=1
              else
                echo "ok — checked $total_git source files"
              fi

              echo ""
              spdx_count="$(
                rg -l 'SPDX-License-Identifier' \
                  --glob '*.py' --glob '*.sh' --glob '*.nix' --glob '*.lean' \
                  "''${RG_SKIP[@]}" . | wc -l | tr -d ' '
              )"
              echo "SPDX-tagged source files (py/sh/nix/lean): $spdx_count"

              if (( fail )); then
                echo ""
                echo "check-license-headers: FAILED" >&2
                exit 1
              fi

              echo ""
              echo "check-license-headers: OK"
            '';
          };

          check-kbee = pkgs.writeShellApplication {
            name = "check-kbee";
            runtimeInputs = [
              check-format-kbee
              check-license-headers
            ];
            text = ''
              set -euo pipefail
              check-format-kbee
              check-license-headers
              echo ""
              echo "check-kbee: OK"
            '';
          };

          install-git-hooks = pkgs.writeShellApplication {
            name = "install-git-hooks";
            runtimeInputs = with pkgs; [bash git];
            text = ''
              set -euo pipefail
              ROOT="$(git rev-parse --show-toplevel)"
              cd "$ROOT"
              git config core.hooksPath .githooks
              echo "git hooksPath set to .githooks (pre-push: format + license/copyright checks)"
            '';
          };

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
        in {
          devShells = {
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
          };
        }
      );
}
