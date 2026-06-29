#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

echo "Checking shell syntax..."
find . -path ./.git -prune -o -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
bash -n install.sh

if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck..."
  shellcheck install.sh scripts/*.sh
else
  echo "shellcheck not found; skipping shellcheck."
fi

echo "Checking tracked files for whitespace errors..."
git diff --check HEAD --

echo "Validation passed."
