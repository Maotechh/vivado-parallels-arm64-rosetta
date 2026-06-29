#!/usr/bin/env bash
set -euo pipefail

: "${INSTALLER:=}"
: "${XILINX_ROOT:=$HOME/Xilinx}"
: "${VIVADO_ROOT:=$XILINX_ROOT/2023.1/Vivado}"

if [ -z "$INSTALLER" ]; then
  cat >&2 <<EOF
No installer was provided.

Download the Linux Unified Installer from AMD/Xilinx, then rerun:
  ./install.sh --installer /path/to/FPGAs_AdaptiveSoCs_Unified_<version>.bin

AMD login, export controls, and EULA acceptance cannot be automated or redistributed here.
EOF
  exit 1
fi

if [ ! -f "$INSTALLER" ]; then
  echo "Installer not found: $INSTALLER" >&2
  exit 1
fi

chmod +x "$INSTALLER"
mkdir -p "$XILINX_ROOT"

cat <<EOF
Launching Vivado installer:
  $INSTALLER

Install location should be:
  $XILINX_ROOT

After the installer exits, this script will continue with wrappers, compiler shims, and udev rules.
EOF

"$INSTALLER"

if [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  echo "Vivado executable was not found at $VIVADO_ROOT/bin/vivado after installer exit." >&2
  echo "If you used a different install path, rerun with --vivado-root /actual/path/Vivado." >&2
  exit 1
fi
