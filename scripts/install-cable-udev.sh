#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:=2023.1}"
: "${VIVADO_ROOT:=$HOME/Xilinx/$VERSION/Vivado}"

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
