#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/generate-install-config.sh /path/to/*Lin64*.bin [output-config]
  scripts/generate-install-config.sh /path/to/extracted-xsetup-dir [output-config]

Runs AMD xsetup -b ConfigGen with the same ARM64/Rosetta uname shim used by
the installer wrapper. The generated config is release-specific.
EOF
}

installer="${1:-}"
output="${2:-}"

if [ -z "$installer" ] || [ "$installer" = "--help" ] || [ "$installer" = "-h" ]; then
  usage
  exit 0
fi

if [ ! -f "$installer" ] && [ ! -d "$installer" ]; then
  echo "Installer not found: $installer" >&2
  exit 1
fi

if [ ! -t 0 ]; then
  echo "ConfigGen is interactive; run this script from a terminal." >&2
  exit 1
fi

cleanup_paths=()
cleanup() {
  local path
  for path in "${cleanup_paths[@]}"; do
    rm -rf "$path"
  done
}
trap cleanup EXIT

make_fake_uname() {
  local fakebin="$1"
  mkdir -p "$fakebin"
  cat > "$fakebin/uname" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-m" ]; then
  echo x86_64
else
  exec /usr/bin/uname "$@"
fi
EOF
  chmod +x "$fakebin/uname"
}

resolve_xsetup_dir() {
  local source_path="$1"
  local extract_dir

  if [ -d "$source_path" ]; then
    if [ -x "$source_path/xsetup" ]; then
      printf '%s\n' "$source_path"
      return 0
    fi
    echo "Installer directory does not contain executable xsetup: $source_path" >&2
    return 1
  fi

  chmod +x "$source_path"
  extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/vivado-configgen.XXXXXX")"
  cleanup_paths+=("$extract_dir")

  echo "Extracting installer to: $extract_dir" >&2
  set +e
  bash "$source_path" --noexec --target "$extract_dir" >&2
  local extract_status=$?
  set -e

  if [ ! -x "$extract_dir/xsetup" ]; then
    echo "xsetup was not found after extraction." >&2
    if [ "$extract_status" -ne 0 ]; then
      exit "$extract_status"
    fi
    exit 1
  fi

  if [ "$extract_status" -ne 0 ]; then
    echo "Installer extraction returned $extract_status, but xsetup exists; continuing." >&2
  fi

  printf '%s\n' "$extract_dir"
}

xsetup_dir="$(resolve_xsetup_dir "$installer")"
fakebin="$(mktemp -d "${TMPDIR:-/tmp}/vivado-fakeuname.XXXXXX")"
cleanup_paths+=("$fakebin")
make_fake_uname "$fakebin"

PATH="$fakebin:$PATH" "$xsetup_dir/xsetup" -b ConfigGen

generated="$HOME/.Xilinx/install_config.txt"
if [ ! -f "$generated" ]; then
  echo "ConfigGen completed, but $generated was not found." >&2
  exit 1
fi

if [ -n "$output" ]; then
  mkdir -p "$(dirname "$output")"
  cp "$generated" "$output"
  echo "Install config copied to: $output"
else
  echo "Install config generated at: $generated"
fi
