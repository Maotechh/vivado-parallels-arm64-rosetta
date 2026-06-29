#!/usr/bin/env bash
set -euo pipefail

echo "Ensuring Rosetta handles x86_64 ELF binaries before qemu-x86_64..."

sudo mkdir -p /etc/binfmt.d

if [ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ] || [ -e /usr/lib/binfmt.d/qemu-x86_64.conf ]; then
  sudo ln -sf /dev/null /etc/binfmt.d/qemu-x86_64.conf
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl restart systemd-binfmt || true
fi

if [ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ]; then
  echo "qemu-x86_64 binfmt is still active. Rosetta may not be first for Vivado." >&2
  echo "Reboot the VM, then rerun this script." >&2
  exit 1
fi

grep -q '/media/psf/RosettaLinux/rosetta' /proc/sys/fs/binfmt_misc/RosettaLinux
echo "Rosetta binfmt is active."
