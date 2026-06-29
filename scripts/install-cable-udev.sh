#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:=}"
: "${XILINX_ROOT:=$HOME/Xilinx}"

if [ -z "${VIVADO_ROOT:-}" ]; then
  if [ -z "$VERSION" ]; then
    echo "Set VERSION or VIVADO_ROOT before running install-cable-udev.sh directly." >&2
    exit 1
  fi
  VIVADO_ROOT="$XILINX_ROOT/$VERSION/Vivado"
fi

if [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  alt_vivado_root="$XILINX_ROOT/Vivado/$VERSION"
  if [ -x "$alt_vivado_root/bin/vivado" ]; then
    VIVADO_ROOT="$alt_vivado_root"
  fi
fi

rules_dir="$VIVADO_ROOT/data/xicom/cable_drivers/lin64/install_script/install_drivers"
if [ ! -d "$rules_dir" ]; then
  echo "Cable driver rules directory not found: $rules_dir" >&2
  exit 1
fi

for rule in 52-xilinx-digilent-usb.rules 52-xilinx-ftdi-usb.rules 52-xilinx-pcusb.rules; do
  if [ -f "$rules_dir/$rule" ]; then
    sudo cp -f "$rules_dir/$rule" "/etc/udev/rules.d/$rule"
    sudo chmod 644 "/etc/udev/rules.d/$rule"
    echo "Installed /etc/udev/rules.d/$rule"
  fi
done

sudo udevadm control --reload-rules
sudo udevadm trigger --action=add || true

for node in /dev/bus/usb/*/*; do
  [ -e "$node" ] || continue
  props="$(udevadm info -q property -n "$node" 2>/dev/null || true)"
  case "$props" in
    *ID_VENDOR_ID=0403*|*ID_VENDOR_ID=03fd*|*ID_VENDOR_ID=1443*)
      sudo chmod 666 "$node" || true
      ;;
  esac
done

echo "Cable udev rules installed. If a target is still missing, unplug and replug the board USB cable."
