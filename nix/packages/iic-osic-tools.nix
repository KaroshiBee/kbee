# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
pkgs:
pkgs.writeShellApplication {
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
}
