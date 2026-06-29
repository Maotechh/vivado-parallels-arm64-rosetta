#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [options]

Options:
  --version VERSION        Vivado version, default: 2023.1
  --xilinx-root DIR        Xilinx install root, default: $HOME/Xilinx
  --vivado-root DIR        Vivado root, default: $XILINX_ROOT/$VERSION/Vivado
  --installer FILE         Already-downloaded AMD/Xilinx Linux Unified Installer
  --skip-installer         Do not run the installer, only prepare and postinstall
  --postinstall-only       Only create wrappers, shims, udev rules, and optional smoke test
  --no-system-shims        Do not replace /usr/bin/gcc, /usr/bin/g++, /usr/bin/ld wrappers
  --smoke                  Run software smoke test after postinstall
  --hardware-detect        Also try Hardware Manager target detection
  --help                   Show this help

Examples:
  ./install.sh --installer ~/Downloads/*2023.1*Lin64*.bin --smoke
  ./install.sh --skip-installer --smoke --hardware-detect
  ./install.sh --postinstall-only --no-system-shims
EOF
}

VERSION="${VERSION:-2023.1}"
XILINX_ROOT="${XILINX_ROOT:-$HOME/Xilinx}"
VIVADO_ROOT="${VIVADO_ROOT:-}"
INSTALLER="${INSTALLER:-}"
SKIP_INSTALLER=0
POSTINSTALL_ONLY=0
INSTALL_SYSTEM_SHIMS="${INSTALL_SYSTEM_SHIMS:-1}"
RUN_SMOKE=0
RUN_HW_DETECT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --xilinx-root)
      XILINX_ROOT="$2"
      shift 2
      ;;
    --vivado-root)
      VIVADO_ROOT="$2"
      shift 2
      ;;
    --installer)
      INSTALLER="$2"
      shift 2
      ;;
    --skip-installer)
      SKIP_INSTALLER=1
      shift
      ;;
    --postinstall-only)
      POSTINSTALL_ONLY=1
      SKIP_INSTALLER=1
      shift
      ;;
    --no-system-shims)
      INSTALL_SYSTEM_SHIMS=0
      shift
      ;;
    --smoke)
      RUN_SMOKE=1
      shift
      ;;
    --hardware-detect)
      RUN_HW_DETECT=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$VIVADO_ROOT" ]; then
  VIVADO_ROOT="$XILINX_ROOT/$VERSION/Vivado"
fi

export VERSION XILINX_ROOT VIVADO_ROOT INSTALLER INSTALL_SYSTEM_SHIMS

"$repo_dir/scripts/check-env.sh"

if [ "$POSTINSTALL_ONLY" -eq 0 ]; then
  "$repo_dir/scripts/prepare-rosetta-binfmt.sh"
  "$repo_dir/scripts/install-deps.sh"
fi

if [ "$SKIP_INSTALLER" -eq 0 ]; then
  if [ -x "$VIVADO_ROOT/bin/vivado" ]; then
    echo "Vivado already exists at $VIVADO_ROOT; skipping installer."
  else
    "$repo_dir/scripts/run-vivado-installer.sh"
  fi
fi

"$repo_dir/scripts/postinstall-vivado.sh"
"$repo_dir/scripts/install-cable-udev.sh"

if [ "$RUN_SMOKE" -eq 1 ]; then
  "$repo_dir/scripts/smoke-test.sh" --software
fi

if [ "$RUN_HW_DETECT" -eq 1 ]; then
  "$repo_dir/scripts/smoke-test.sh" --hardware-detect
fi

cat <<EOF

Install/postinstall flow completed.
Vivado wrapper: $HOME/.local/bin/vivado
Run Vivado:      vivado -mode gui
Smoke test:      ./scripts/smoke-test.sh --software
EOF
