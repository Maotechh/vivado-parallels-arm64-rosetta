# Installation Guide

This guide assumes an Apple Silicon Mac running an Ubuntu ARM64 VM in Parallels Desktop.

## Prerequisites

- Parallels Desktop with Rosetta for Linux enabled.
- Parallels Tools installed in the Ubuntu guest.
- Ubuntu packages can be installed with `sudo apt`.
- The AMD/Xilinx Linux Unified Installer has already been downloaded from AMD.

The installer file is usually named like:

```text
*_Lin64.bin
```

## Interactive Install

```bash
./install.sh --version <version> --installer ~/Downloads/*<version>*Lin64*.bin --smoke
```

The script will:

- Check that the guest is ARM64 Linux and that Parallels Rosetta binfmt is available.
- Prefer Rosetta over QEMU for x86_64 ELF execution.
- Enable Ubuntu `amd64` packages and install runtime dependencies.
- Extract the AMD `.bin` installer and run `xsetup` with an ARM64-safe `uname` shim.
- Run postinstall configuration after `xsetup` exits.
- Run the software smoke test if `--smoke` is provided.

## Batch Install

Generate a release-specific config:

```bash
./scripts/generate-install-config.sh ~/Downloads/*<version>*Lin64*.bin install_config.txt
```

Edit the generated config to select products, devices, and install location. Then run:

```bash
./install.sh --version <version> \
  --installer ~/Downloads/*<version>*Lin64*.bin \
  --install-config install_config.txt \
  --accept-eulas \
  --smoke
```

`--accept-eulas` is intentionally explicit. It passes this to AMD `xsetup`:

```text
-a XilinxEULA,3rdPartyEULA
```

## Existing Install

If Vivado is already present and you only need wrappers, shims, udev rules, and smoke tests:

```bash
./install.sh --version <version> --skip-installer --smoke
```

The scripts auto-detect both common Vivado layouts:

```text
~/Xilinx/<version>/Vivado
~/Xilinx/Vivado/<version>
```

You can override the detected path:

```bash
./install.sh --vivado-root /path/to/Vivado/<version> --skip-installer --smoke
```

## Desktop Entry

Postinstall creates:

```text
~/.local/bin/vivado
~/.local/share/applications/vivado-<version>.desktop
```

The desktop entry runs:

```bash
~/.local/bin/vivado -mode gui
```

It also updates the desktop database and appends the entry to GNOME's app-picker layout when that setting exists.

## Hardware Setup

For JTAG, attach the board or cable to the Ubuntu VM from the Parallels USB menu. Then check:

```bash
lsusb
```

Digilent FTDI cables commonly appear as devices such as:

```text
0403:6014
```

Run:

```bash
./scripts/smoke-test.sh --hardware-detect
```

For safe programming:

```bash
VIVADO_PART=<vivado-part> HW_PART=<hardware-part-prefix> ./scripts/smoke-test.sh --hardware-program
```
