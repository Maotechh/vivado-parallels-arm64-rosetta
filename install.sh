#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [options]

Options:
  --version VERSION        Vivado version; required unless inferable from installer or --vivado-root
  --xilinx-root DIR        Xilinx install root, default: $HOME/Xilinx
  --vivado-root DIR        Vivado root, default: $XILINX_ROOT/$VERSION/Vivado
  --installer FILE         Already-downloaded AMD/Xilinx Linux Unified Installer
  --install-config FILE    Run xsetup in batch mode with this generated config file
  --accept-eulas           Required with --install-config; accepts Xilinx and 3rd-party EULAs
  --skip-installer         Do not run the installer, only prepare and postinstall
  --postinstall-only       Only create wrappers, shims, udev rules, and optional smoke test
  --no-system-shims        Do not replace /usr/bin/gcc, /usr/bin/g++, /usr/bin/ld wrappers
  --smoke                  Run software smoke test after postinstall
  --hardware-detect        Also try Hardware Manager target detection
  --help                   Show this help

Examples:
  ./install.sh --version <version> --installer ~/Downloads/*<version>*Lin64*.bin --smoke
  ./install.sh --version <version> --installer ~/Downloads/*<version>*Lin64*.bin --install-config install_config.txt --accept-eulas --smoke
  ./install.sh --version <version> --skip-installer --smoke --hardware-detect
  ./install.sh --postinstall-only --no-system-shims
EOF
}

VERSION="${VERSION:-}"
XILINX_ROOT="${XILINX_ROOT:-$HOME/Xilinx}"
VIVADO_ROOT="${VIVADO_ROOT:-}"
INSTALLER="${INSTALLER:-}"
INSTALL_CONFIG="${INSTALL_CONFIG:-}"
ACCEPT_EULAS="${ACCEPT_EULAS:-0}"
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
    --install-config)
      INSTALL_CONFIG="$2"
      shift 2
      ;;
    --accept-eulas)
      ACCEPT_EULAS=1
      shift
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

infer_version_from_path() {
  local value="$1"
  local inferred=""
  inferred="$(printf '%s\n' "$value" | grep -Eo '[0-9]{4}\.[0-9]+' | head -n 1 || true)"
  printf '%s\n' "$inferred"
}

detect_installed_vivado_root() {
  local candidate
  for candidate in "$VIVADO_ROOT" "$XILINX_ROOT/$VERSION/Vivado" "$XILINX_ROOT/Vivado/$VERSION"; do
    [ -n "$candidate" ] || continue
    if [ -x "$candidate/bin/vivado" ]; then
      VIVADO_ROOT="$candidate"
      export VIVADO_ROOT
      return 0
    fi
  done
  return 1
}

if [ -z "$VIVADO_ROOT" ]; then
  if [ -z "$VERSION" ] && [ -n "$INSTALLER" ]; then
    VERSION="$(infer_version_from_path "$INSTALLER")"
  fi
  VIVADO_ROOT="$XILINX_ROOT/$VERSION/Vivado"
fi

if [ -z "$VERSION" ]; then
  VERSION="$(infer_version_from_path "$VIVADO_ROOT")"
fi

if [ -z "$VERSION" ]; then
  cat >&2 <<'EOF'
Unable to infer Vivado version.
Pass --version <version>, or pass --vivado-root /path/to/<version>/Vivado.
EOF
  exit 1
fi

export VERSION XILINX_ROOT VIVADO_ROOT INSTALLER INSTALL_CONFIG ACCEPT_EULAS INSTALL_SYSTEM_SHIMS

"$repo_dir/scripts/check-env.sh"

if [ "$POSTINSTALL_ONLY" -eq 0 ]; then
  "$repo_dir/scripts/prepare-rosetta-binfmt.sh"
  "$repo_dir/scripts/install-deps.sh"
fi

detect_installed_vivado_root || true

if [ "$SKIP_INSTALLER" -eq 0 ]; then
  if [ -x "$VIVADO_ROOT/bin/vivado" ]; then
    echo "Vivado already exists at $VIVADO_ROOT; skipping installer."
  else
    "$repo_dir/scripts/run-vivado-installer.sh"
    detect_installed_vivado_root || true
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
