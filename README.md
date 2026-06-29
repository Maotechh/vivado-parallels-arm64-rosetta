# Vivado Parallels ARM64 Rosetta Installer

[![CI](https://github.com/Maotechh/vivado-parallels-arm64-rosetta/actions/workflows/ci.yml/badge.svg)](https://github.com/Maotechh/vivado-parallels-arm64-rosetta/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Install and post-configure AMD Vivado for Linux inside an Ubuntu ARM64 VM on Apple Silicon, using Parallels Desktop's Rosetta x86_64 emulation.

Vivado's Linux release is x86_64-only. This project provides the glue needed for the installer, GUI, XSim, and JTAG tooling to work from an ARM64 Ubuntu guest without redistributing any AMD/Xilinx proprietary files.

## Status

This is an installer helper, not a Vivado mirror. You still need to download the official AMD/Xilinx Linux Unified Installer yourself and satisfy AMD account, export-control, license, and EULA requirements.

Tested environment:

| Component | Tested |
| --- | --- |
| Host | Apple Silicon Mac |
| VM | Parallels Desktop Ubuntu ARM64 |
| Emulation | Parallels Rosetta for Linux |
| Ubuntu | 24.04 ARM64 |
| Vivado | Tested with Vivado 2026.1 and 2023.2 |

## What It Handles

- Routes x86_64 ELF execution to Parallels Rosetta instead of QEMU user emulation.
- Works around AMD `xsetup` and Vivado launcher `uname -m` checks on ARM64.
- Installs required `amd64` runtime libraries, compiler toolchains, USB libraries, and GTK dependencies.
- Creates a stable `~/.local/bin/vivado` wrapper for CLI and GUI use.
- Adds XSim compiler/linker shims so x86_64 simulator elaboration does not accidentally use ARM64 host tools.
- Installs Xilinx/Digilent cable udev rules for JTAG.
- Provides software and optional hardware smoke tests.

## Quick Start

1. Enable Rosetta for Linux in Parallels Desktop and install Parallels Tools.

2. Download the AMD/Xilinx Linux Unified Installer, for example a `*Lin64*.bin` file, from AMD.

3. Install and run the software smoke test:

```bash
git clone https://github.com/Maotechh/vivado-parallels-arm64-rosetta.git
cd vivado-parallels-arm64-rosetta
./install.sh --version <version> --installer ~/Downloads/*<version>*Lin64*.bin --smoke
```

If Vivado is already installed:

```bash
./install.sh --version <version> --skip-installer --smoke
```

For a batch install:

```bash
./scripts/generate-install-config.sh ~/Downloads/*<version>*Lin64*.bin install_config.txt
./install.sh --version <version> \
  --installer ~/Downloads/*<version>*Lin64*.bin \
  --install-config install_config.txt \
  --accept-eulas \
  --smoke
```

## Verify

Software smoke test:

```bash
./scripts/smoke-test.sh --software
```

Expected markers include:

```text
SMOKE_SIM_PASS
SMOKE_STEP_PASS synthesis
SMOKE_STEP_PASS implementation_bitstream
SMOKE_STEP_PASS ip_create_generate
SMOKE_ALL_PASS
```

Hardware detection, after assigning the board USB/JTAG cable to the VM:

```bash
./scripts/smoke-test.sh --hardware-detect
```

Safe JTAG programming test:

```bash
VIVADO_PART=xc7a200tsbg484-1 HW_PART=xc7a200t ./scripts/smoke-test.sh --hardware-program
```

Change `VIVADO_PART` and `HW_PART` for your FPGA. The programming smoke test generates a no-external-IO bitstream using `STARTUPE2.CFGMCLK`.

## Documentation

- [Installation Guide](docs/installation.md)
- [How It Works](docs/how-it-works.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Verification Notes](docs/verification.md)

## Repository Layout

```text
install.sh                    Main install/postinstall entry point
scripts/                      Installer, dependency, udev, validation, and recovery scripts
smoke/src/                    Tiny Verilog designs used by smoke tests
smoke/tcl/                    Vivado Tcl smoke-test flows
docs/                         User and maintainer documentation
```

## Safety Notes

- The scripts do not download Vivado or embed AMD credentials.
- The scripts do not redistribute AMD/Xilinx proprietary installers, device files, IP, or licenses.
- System compiler/linker shims are optional but enabled by default because some XSim flows need them. Restore backups with `./scripts/restore-system-shims.sh`.
- Hardware behavior depends on Parallels USB assignment. If `lsusb` does not show the JTAG cable inside Ubuntu, Vivado cannot see it.

## License

The scripts and documentation in this repository are released under the MIT License. AMD/Xilinx Vivado and related files remain subject to AMD/Xilinx terms.
