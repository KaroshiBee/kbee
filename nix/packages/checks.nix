# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
pkgs: let
  formatInputs = with pkgs; [
    bash
    git
    coreutils
    ruff
    shfmt
    alejandra
    mdformat
    taplo
  ];

  check-format-kbee = pkgs.writeShellApplication {
    name = "check-format-kbee";
    runtimeInputs = formatInputs;
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

  format-kbee = pkgs.writeShellApplication {
    name = "format-kbee";
    runtimeInputs = formatInputs;
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
in {
  inherit
    format-kbee
    check-format-kbee
    check-license-headers
    check-kbee
    install-git-hooks
    ;
}
