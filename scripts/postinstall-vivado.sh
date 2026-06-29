#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:=2026.1}"
: "${VIVADO_ROOT:=$HOME/Xilinx/$VERSION/Vivado}"
: "${INSTALL_SYSTEM_SHIMS:=1}"

if [ ! -f "$VIVADO_ROOT/settings64.sh" ] || [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  echo "Vivado installation was not found at: $VIVADO_ROOT" >&2
  echo "Set VIVADO_ROOT or pass --vivado-root." >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/xilinx-x86_64-tools" "$HOME/.local/share/applications"

cat > "$HOME/.local/xilinx-x86_64-tools/gcc" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/x86_64-linux-gnu-gcc "$@"
EOF
cat > "$HOME/.local/xilinx-x86_64-tools/g++" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/x86_64-linux-gnu-g++ "$@"
EOF
chmod +x "$HOME/.local/xilinx-x86_64-tools/gcc" "$HOME/.local/xilinx-x86_64-tools/g++"

cat > "$HOME/.local/bin/vivado" <<EOF
#!/usr/bin/env bash
set -euo pipefail

source "$VIVADO_ROOT/settings64.sh"
export PATH="$HOME/.local/xilinx-x86_64-tools:\$PATH"
exec "$VIVADO_ROOT/bin/vivado" "\$@"
EOF
chmod +x "$HOME/.local/bin/vivado"

icon="$VIVADO_ROOT/doc/images/vivado_logo.png"
cat > "$HOME/.local/share/applications/vivado-$VERSION.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Vivado $VERSION
Comment=AMD Vivado Design Suite
Exec=$HOME/.local/bin/vivado
Icon=$icon
Terminal=false
Categories=Development;Electronics;
StartupNotify=true
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if [ "$INSTALL_SYSTEM_SHIMS" -eq 1 ]; then
  backup_suffix=".vivado-arm64-rosetta-backup"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  backup_once() {
    local path="$1"
    local backup="$path$backup_suffix"
    if [ ! -e "$backup" ]; then
      sudo cp -a "$path" "$backup"
    fi
  }

  backup_once /usr/bin/gcc
  backup_once /usr/bin/g++
  backup_once /usr/bin/ld

  vivado_ld="$(find "$(dirname "$VIVADO_ROOT")/tps" -type f -path '*x86_64-pc-linux-gnu/bin/ld' 2>/dev/null | sort | tail -n 1 || true)"
  if [ -z "$vivado_ld" ]; then
    vivado_ld="/usr/bin/x86_64-linux-gnu-ld"
  fi

  cat > "$tmp_dir/gcc" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
    -m64|-m32)
      unset GCC_EXEC_PREFIX COMPILER_PATH LIBRARY_PATH
      exec /usr/bin/x86_64-linux-gnu-gcc "\$@"
      ;;
  esac
done
exec /usr/bin/gcc$backup_suffix "\$@"
EOF

  cat > "$tmp_dir/g++" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
    -m64|-m32)
      unset GCC_EXEC_PREFIX COMPILER_PATH LIBRARY_PATH
      exec /usr/bin/x86_64-linux-gnu-g++ "\$@"
      ;;
  esac
done
exec /usr/bin/g++$backup_suffix "\$@"
EOF

  cat > "$tmp_dir/ld" <<EOF
#!/usr/bin/env bash
VIVADO_LD="$vivado_ld"
prev=""
for arg in "\$@"; do
  if [ "\$prev" = "-m" ] && [ "\$arg" = "elf_x86_64" ]; then
    exec "\$VIVADO_LD" "\$@"
  fi
  case "\$arg" in
    -melf_x86_64|elf_x86_64|*x86_64*)
      exec "\$VIVADO_LD" "\$@"
      ;;
  esac
  prev="\$arg"
done
exec /usr/bin/ld$backup_suffix "\$@"
EOF

  chmod +x "$tmp_dir/gcc" "$tmp_dir/g++" "$tmp_dir/ld"
  sudo install -m 0755 "$tmp_dir/gcc" /usr/bin/gcc
  sudo install -m 0755 "$tmp_dir/g++" /usr/bin/g++
  sudo install -m 0755 "$tmp_dir/ld" /usr/bin/ld
fi

echo "Vivado wrapper installed at $HOME/.local/bin/vivado"
