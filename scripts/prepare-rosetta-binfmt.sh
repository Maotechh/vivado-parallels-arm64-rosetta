#!/usr/bin/env bash
set -euo pipefail

echo "Ensuring Rosetta handles x86_64 ELF binaries before qemu-x86_64..."

sudo mkdir -p /etc/binfmt.d

register_rosetta() {
  local tmp_file
  tmp_file="$(mktemp)"
  cat > "$tmp_file" <<'EOF'
:RosettaLinux:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/media/psf/RosettaLinux/rosetta:OP
EOF
  sudo sh -c "cat '$tmp_file' > /proc/sys/fs/binfmt_misc/register"
  rm -f "$tmp_file"
}

if [ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ] || [ -e /usr/lib/binfmt.d/qemu-x86_64.conf ]; then
  sudo ln -sf /dev/null /etc/binfmt.d/qemu-x86_64.conf
fi

if [ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ]; then
  echo -1 | sudo tee /proc/sys/fs/binfmt_misc/qemu-x86_64 >/dev/null
fi

if [ -e /proc/sys/fs/binfmt_misc/qemu-x86_64 ]; then
  echo "qemu-x86_64 binfmt is still active. Rosetta may not be first for Vivado." >&2
  exit 1
fi

if [ ! -f /proc/sys/fs/binfmt_misc/RosettaLinux ]; then
  register_rosetta
fi

grep -q '/media/psf/RosettaLinux/rosetta' /proc/sys/fs/binfmt_misc/RosettaLinux
echo "Rosetta binfmt is active."
