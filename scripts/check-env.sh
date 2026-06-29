#!/usr/bin/env bash
set -euo pipefail

arch="$(uname -m)"
case "$arch" in
  aarch64|arm64)
    ;;
  *)
    echo "This workflow targets ARM64 Linux. Current arch: $arch" >&2
    exit 1
    ;;
esac

if [ ! -d /proc/sys/fs/binfmt_misc ]; then
  echo "binfmt_misc is not mounted." >&2
  echo "Try: sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc" >&2
  exit 1
fi

if [ ! -x /media/psf/RosettaLinux/rosetta ]; then
  echo "Parallels Rosetta Linux interpreter was not found at /media/psf/RosettaLinux/rosetta." >&2
  echo "Enable Rosetta for Linux in Parallels Desktop and make sure Parallels Tools are installed." >&2
  exit 1
fi

if [ -f /proc/sys/fs/binfmt_misc/RosettaLinux ]; then
  if ! grep -q '^enabled$' /proc/sys/fs/binfmt_misc/RosettaLinux; then
    echo "RosettaLinux binfmt entry exists but is not enabled." >&2
    exit 1
  fi
else
  echo "RosettaLinux binfmt entry is missing. Reboot the VM or reinstall Parallels Tools." >&2
  exit 1
fi

echo "Environment check passed: $arch with RosettaLinux binfmt."
