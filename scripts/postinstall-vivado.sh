#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:=}"
: "${XILINX_ROOT:=$HOME/Xilinx}"
: "${INSTALL_SYSTEM_SHIMS:=1}"

if [ -z "${VIVADO_ROOT:-}" ]; then
  if [ -z "$VERSION" ]; then
    echo "Set VERSION or VIVADO_ROOT before running postinstall-vivado.sh directly." >&2
    exit 1
  fi
  VIVADO_ROOT="$XILINX_ROOT/$VERSION/Vivado"
fi

if [ -z "$VERSION" ]; then
  VERSION="$(printf '%s\n' "$VIVADO_ROOT" | grep -Eo '[0-9]{4}\.[0-9]+' | head -n 1 || true)"
fi
if [ -z "$VERSION" ]; then
  VERSION="custom"
fi

if [ ! -f "$VIVADO_ROOT/settings64.sh" ] || [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  alt_vivado_root="$XILINX_ROOT/Vivado/$VERSION"
  if [ -f "$alt_vivado_root/settings64.sh" ] && [ -x "$alt_vivado_root/bin/vivado" ]; then
    VIVADO_ROOT="$alt_vivado_root"
  fi
fi

if [ ! -f "$VIVADO_ROOT/settings64.sh" ] || [ ! -x "$VIVADO_ROOT/bin/vivado" ]; then
  echo "Vivado installation was not found at: $VIVADO_ROOT" >&2
  echo "Set VIVADO_ROOT or pass --vivado-root." >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/xilinx-x86_64-tools" "$HOME/.local/xilinx-x86_64-libs" "$HOME/.local/share/applications"

if [ ! -e "$HOME/.local/xilinx-x86_64-libs/libtinfo.so.5" ]; then
  if [ -e /usr/lib/x86_64-linux-gnu/libtinfo.so.5 ]; then
    ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.5 "$HOME/.local/xilinx-x86_64-libs/libtinfo.so.5"
  elif [ -e /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]; then
    ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 "$HOME/.local/xilinx-x86_64-libs/libtinfo.so.5"
  fi
fi

cat > "$HOME/.local/xilinx-x86_64-tools/gcc" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/x86_64-linux-gnu-gcc "$@"
EOF
cat > "$HOME/.local/xilinx-x86_64-tools/g++" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/x86_64-linux-gnu-g++ "$@"
EOF
cat > "$HOME/.local/xilinx-x86_64-tools/uname" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-m" ]; then
  echo x86_64
else
  exec /usr/bin/uname "$@"
fi
EOF
chmod +x "$HOME/.local/xilinx-x86_64-tools/gcc" "$HOME/.local/xilinx-x86_64-tools/g++" "$HOME/.local/xilinx-x86_64-tools/uname"

cat > "$HOME/.local/bin/vivado" <<EOF
#!/usr/bin/env bash
set -euo pipefail

source "$VIVADO_ROOT/settings64.sh"
export PATH="$HOME/.local/xilinx-x86_64-tools:\$PATH"
export LD_LIBRARY_PATH="$HOME/.local/xilinx-x86_64-libs:\${LD_LIBRARY_PATH:-}"
unset GIO_LAUNCHED_DESKTOP_FILE GIO_LAUNCHED_DESKTOP_FILE_PID
exec "$VIVADO_ROOT/bin/vivado" "\$@"
EOF
chmod +x "$HOME/.local/bin/vivado"

icon="$VIVADO_ROOT/doc/images/vivado_logo.png"
desktop_id="vivado-$VERSION.desktop"
desktop_file="$HOME/.local/share/applications/$desktop_id"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Vivado $VERSION
Comment=AMD Vivado Design Suite
Exec=$HOME/.local/bin/vivado -mode gui
Icon=$icon
Terminal=false
Categories=Development;Electronics;
Keywords=Vivado;Xilinx;AMD;FPGA;Verilog;VHDL;Synthesis;
StartupNotify=true
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v python3 >/dev/null 2>&1 && command -v gsettings >/dev/null 2>&1; then
  python3 - "$desktop_id" <<'PY' >/dev/null 2>&1 || true
import sys

try:
    from gi.repository import Gio, GLib
except Exception:
    raise SystemExit(0)

app_id = sys.argv[1]
settings = Gio.Settings.new("org.gnome.shell")
layout = settings.get_value("app-picker-layout").unpack()
if not layout:
    raise SystemExit(0)

page = dict(layout[0])
if app_id in page:
    raise SystemExit(0)

positions = []
for value in page.values():
    if isinstance(value, dict) and "position" in value:
        positions.append(int(value["position"]))

page[app_id] = {"position": (max(positions) + 1) if positions else 0}

def scalar_variant(value):
    if isinstance(value, bool):
        return GLib.Variant("b", value)
    if isinstance(value, int):
        return GLib.Variant("i", value)
    if isinstance(value, str):
        return GLib.Variant("s", value)
    return None

def page_variant(raw_page):
    converted = {}
    for key, value in raw_page.items():
        if not isinstance(value, dict):
            continue
        inner = {}
        for inner_key, inner_value in value.items():
            variant = scalar_variant(inner_value)
            if variant is not None:
                inner[inner_key] = variant
        if inner:
            converted[key] = GLib.Variant("a{sv}", inner)
    return converted

layout[0] = page
settings.set_value("app-picker-layout", GLib.Variant("aa{sv}", [page_variant(p) for p in layout]))
settings.sync()
PY
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
