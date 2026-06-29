#!/usr/bin/env bash
set -euo pipefail

: "${INSTALLER:=}"
: "${INSTALL_CONFIG:=}"
: "${ACCEPT_EULAS:=0}"
: "${XILINX_ROOT:=$HOME/Xilinx}"
: "${VERSION:=}"

if [ -z "$VERSION" ] && [ -n "$INSTALLER" ]; then
  VERSION="$(printf '%s\n' "$INSTALLER" | grep -Eo '[0-9]{4}\.[0-9]+' | head -n 1 || true)"
fi

if [ -z "${VIVADO_ROOT:-}" ]; then
  if [ -z "$VERSION" ]; then
    echo "Unable to infer Vivado version from installer path. Pass --version <version>." >&2
    exit 1
  fi
  VIVADO_ROOT="$XILINX_ROOT/$VERSION/Vivado"
fi

detect_installed_vivado_root() {
  local candidate
  for candidate in "$VIVADO_ROOT" "$XILINX_ROOT/$VERSION/Vivado" "$XILINX_ROOT/Vivado/$VERSION"; do
    [ -n "$candidate" ] || continue
    if [ -x "$candidate/bin/vivado" ]; then
      VIVADO_ROOT="$candidate"
      return 0
    fi
  done
  return 1
}

if [ -z "$INSTALLER" ]; then
  cat >&2 <<EOF
No installer was provided.

Download the Linux Unified Installer from AMD/Xilinx, then rerun:
  ./install.sh --version <version> --installer /path/to/*<version>*Lin64*.bin

AMD login, export controls, and EULA acceptance cannot be automated or redistributed here.
EOF
  exit 1
fi

if [ ! -f "$INSTALLER" ] && [ ! -d "$INSTALLER" ]; then
  echo "Installer not found: $INSTALLER" >&2
  exit 1
fi

if [ -n "$INSTALL_CONFIG" ] && [ ! -f "$INSTALL_CONFIG" ]; then
  echo "Install config not found: $INSTALL_CONFIG" >&2
  exit 1
fi

if [ -n "$INSTALL_CONFIG" ] && [ "$ACCEPT_EULAS" != "1" ]; then
  cat >&2 <<EOF
Batch install with --install-config requires explicit --accept-eulas.
This passes xsetup: -a XilinxEULA,3rdPartyEULA
EOF
  exit 1
fi

mkdir -p "$XILINX_ROOT"

cat <<EOF
Preparing Vivado installer:
  $INSTALLER

Install location should be:
  $XILINX_ROOT

After xsetup exits, this script will continue with wrappers, compiler shims, and udev rules.
EOF

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
  local installer="$1"
  local extract_dir

  if [ -d "$installer" ]; then
    if [ -x "$installer/xsetup" ]; then
      printf '%s\n' "$installer"
      return 0
    fi
    echo "Installer directory does not contain executable xsetup: $installer" >&2
    return 1
  fi

  chmod +x "$installer"
  extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/vivado-xsetup-${VERSION:-unknown}.XXXXXX")"
  cleanup_paths+=("$extract_dir")

  echo "Extracting installer to: $extract_dir" >&2
  set +e
  bash "$installer" --noexec --target "$extract_dir" >&2
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

xsetup_dir="$(resolve_xsetup_dir "$INSTALLER")"
fakebin="$(mktemp -d "${TMPDIR:-/tmp}/vivado-fakeuname.XXXXXX")"
cleanup_paths+=("$fakebin")
make_fake_uname "$fakebin"

if [ -n "$INSTALL_CONFIG" ]; then
  echo "Running xsetup batch install with config: $INSTALL_CONFIG"
  PATH="$fakebin:$PATH" "$xsetup_dir/xsetup" -a XilinxEULA,3rdPartyEULA -b Install -c "$INSTALL_CONFIG"
else
  cat <<EOF
Launching xsetup GUI.

On ARM64 Parallels Linux, this wrapper makes xsetup see uname -m as x86_64
so the x86_64 installer can run under Rosetta.
EOF
  PATH="$fakebin:$PATH" "$xsetup_dir/xsetup"
fi

detect_installed_vivado_root || true

if [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  echo "Vivado executable was not found at $VIVADO_ROOT/bin/vivado after installer exit." >&2
  echo "If you used a different install path, rerun with --vivado-root /actual/path/to/Vivado." >&2
  exit 1
fi

echo "Vivado executable found at $VIVADO_ROOT/bin/vivado"
