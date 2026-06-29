#!/usr/bin/env bash
set -euo pipefail

backup_suffix=".vivado-arm64-rosetta-backup"

for tool in gcc g++ ld; do
  if [ -e "/usr/bin/$tool$backup_suffix" ]; then
    sudo mv -f "/usr/bin/$tool$backup_suffix" "/usr/bin/$tool"
    echo "Restored /usr/bin/$tool"
  else
    echo "No backup found for /usr/bin/$tool"
  fi
done
