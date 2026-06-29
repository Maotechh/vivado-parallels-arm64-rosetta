#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
vivado_bin="${VIVADO_BIN:-$HOME/.local/bin/vivado}"
mode="${1:---software}"

if [ ! -x "$vivado_bin" ]; then
  echo "Vivado wrapper not found: $vivado_bin" >&2
  echo "Set VIVADO_BIN or run ./install.sh first." >&2
  exit 1
fi

case "$mode" in
  --software)
    "$vivado_bin" -mode batch -nojournal -log "$repo_dir/smoke/software_smoke.log" -source "$repo_dir/smoke/tcl/run_smoke.tcl"
    ;;
  --hardware-detect)
    "$vivado_bin" -mode batch -nojournal -log "$repo_dir/smoke/hw_detect.log" -source "$repo_dir/smoke/tcl/run_hw_detect.tcl"
    ;;
  --hardware-program)
    vivado_part="${VIVADO_PART:-xc7a200tsbg484-1}"
    hw_part="${HW_PART:-xc7a200t}"
    "$vivado_bin" -mode batch -nojournal -log "$repo_dir/smoke/artix_bitstream.log" -source "$repo_dir/smoke/tcl/run_safe_bitstream.tcl" -tclargs "$vivado_part"
    bit_file="$repo_dir/smoke/hw_program_work/bit/jtag_safe_top.bit"
    "$vivado_bin" -mode batch -nojournal -log "$repo_dir/smoke/hw_program.log" -source "$repo_dir/smoke/tcl/run_hw_program.tcl" -tclargs "$bit_file" "$hw_part"
    ;;
  *)
    cat >&2 <<'EOF'
Usage:
  ./scripts/smoke-test.sh --software
  ./scripts/smoke-test.sh --hardware-detect
  VIVADO_PART=xc7a200tsbg484-1 HW_PART=xc7a200t ./scripts/smoke-test.sh --hardware-program
EOF
    exit 2
    ;;
esac
