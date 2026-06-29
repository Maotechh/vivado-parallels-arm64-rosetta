# Vivado on Parallels ARM64 Linux with Rosetta

This repo documents and scripts a verified Vivado installation flow for:

- Apple Silicon Mac
- Parallels Desktop Ubuntu ARM64 VM
- Rosetta Linux x86_64 emulation
- AMD Vivado 2023.1

The goal is to make the repeatable part one-command:

```bash
./install.sh --installer ~/Downloads/*2023.1*Lin64*.bin --smoke
```

AMD account login, export-control checks, license terms, and the installer download cannot be redistributed or bypassed. Download the official Linux Unified Installer from AMD first, then run this repo's script.

## Verified Result

This repo targets Vivado 2023.1. The Rosetta/binfmt, x86_64 compiler shim, udev, and smoke-test workflow was developed on Ubuntu 24.04.4 ARM64 under Parallels Desktop; run the included smoke tests after installing 2023.1 to validate your machine.

- Vivado install root defaults to `~/Xilinx/2023.1/Vivado`.
- Vivado GUI launches through Rosetta.
- BASIC license was detected by Vivado.
- XSim behavioral simulation passed with `SMOKE_SIM_PASS`.
- Project-mode synthesis passed with 0 errors.
- Implementation and bitstream generation passed.
- `clk_wiz` IP catalog, generation, and OOC synthesis passed.
- Hardware Manager started `hw_server` and `cs_server`.
- Digilent FTDI JTAG target was detected.
- FPGA device was detected as `xc7a200t`.
- A safe no-external-IO `xc7a200t` bitstream was generated and programmed.
- Vivado reported `End of startup status: HIGH` after JTAG programming.

## What This Fixes

Vivado for Linux is x86_64-only. In an ARM64 Ubuntu VM, several things fail unless they are handled explicitly:

- Linux must route x86_64 ELF binaries to Parallels Rosetta, not QEMU user emulation.
- Ubuntu must have enough `amd64` runtime libraries for x86_64 Vivado binaries.
- XSim invokes host compiler/linker tools; on ARM64 it can accidentally call ARM `gcc`/`ld`, which breaks x86_64 simulation elaboration.
- JTAG cable access needs Xilinx/Digilent udev rules, otherwise `hw_server` can connect but find no targets.

This repo handles those points.

## Quick Start

1. Enable Rosetta for Linux in Parallels Desktop and install Parallels Tools.

2. Download the AMD/Xilinx Linux Unified Installer.

3. Run:

```bash
git clone https://github.com/Maotechh/vivado-parallels-arm64-rosetta.git
cd vivado-parallels-arm64-rosetta
./install.sh --installer ~/Downloads/*2023.1*Lin64*.bin --smoke
```

If Vivado is already installed:

```bash
./install.sh --skip-installer --smoke
```

If the board is plugged in and assigned to the VM:

```bash
./install.sh --skip-installer --smoke --hardware-detect
```

To program a safe JTAG test bitstream:

```bash
VIVADO_PART=xc7a200tsbg484-1 HW_PART=xc7a200t ./scripts/smoke-test.sh --hardware-program
```

Change `VIVADO_PART` and `HW_PART` for your FPGA. The test design has no external IO pins and only uses a tiny internal heartbeat register driven from `STARTUPE2.CFGMCLK`.

## Scripts

- `install.sh`: main entry point.
- `scripts/check-env.sh`: checks ARM64 Linux and Rosetta binfmt.
- `scripts/prepare-rosetta-binfmt.sh`: masks `qemu-x86_64` so Rosetta handles x86_64 ELF.
- `scripts/install-deps.sh`: enables `amd64` architecture and installs runtime/cross-compiler packages.
- `scripts/run-vivado-installer.sh`: launches the AMD installer you downloaded.
- `scripts/postinstall-vivado.sh`: creates the Vivado wrapper, desktop entry, compiler wrappers, and optional system compiler/linker shims.
- `scripts/install-cable-udev.sh`: installs Xilinx cable udev rules and reloads udev.
- `scripts/smoke-test.sh`: runs software, hardware-detect, or hardware-program smoke tests.
- `scripts/restore-system-shims.sh`: restores `/usr/bin/gcc`, `/usr/bin/g++`, and `/usr/bin/ld` if system shims were installed.

## Important Design Choices

### Rosetta Must Win Over QEMU

The working setup has:

```text
/proc/sys/fs/binfmt_misc/RosettaLinux
interpreter /media/psf/RosettaLinux/rosetta
```

and masks QEMU's x86_64 handler with:

```text
/etc/binfmt.d/qemu-x86_64.conf -> /dev/null
```

This avoids Vivado and XSim running under QEMU when Rosetta is available.

### XSim Compiler/Linker Shims

The failure mode was XSim using ARM host compiler/linker components while elaborating an x86_64 simulator snapshot. The fix is:

- Install `gcc-x86-64-linux-gnu`, `g++-x86-64-linux-gnu`, and `libc6-dev:amd64`.
- Put x86_64 `gcc`/`g++` wrappers ahead of Vivado's PATH via `~/.local/bin/vivado`.
- Optionally install system shims for `/usr/bin/gcc`, `/usr/bin/g++`, and `/usr/bin/ld`.

The system shims are invasive but backed up automatically as:

```text
/usr/bin/gcc.vivado-arm64-rosetta-backup
/usr/bin/g++.vivado-arm64-rosetta-backup
/usr/bin/ld.vivado-arm64-rosetta-backup
```

Restore them with:

```bash
./scripts/restore-system-shims.sh
```

If you do not want system shims:

```bash
./install.sh --skip-installer --no-system-shims
```

Be aware that XSim may fail on some Vivado versions without the system shims.

### JTAG USB Rules

The board was visible in `lsusb`, but Vivado initially found no hardware targets because `/dev/bus/usb/...` was not writable by the user. Installing these Vivado-provided udev rules fixed it:

- `52-xilinx-digilent-usb.rules`
- `52-xilinx-ftdi-usb.rules`
- `52-xilinx-pcusb.rules`

If `hw_server` still finds no target after installing rules, unplug and replug the board USB cable, and verify the USB device is attached to the VM in Parallels.

## Smoke Tests

Software test:

```bash
./scripts/smoke-test.sh --software
```

Expected markers:

```text
SMOKE_SIM_PASS
SMOKE_STEP_PASS synthesis
SMOKE_STEP_PASS implementation_bitstream
SMOKE_STEP_PASS ip_create_generate
SMOKE_ALL_PASS
```

Hardware detection:

```bash
./scripts/smoke-test.sh --hardware-detect
```

Expected markers:

```text
SMOKE_HW_TARGET_COUNT 1
SMOKE_HW_DEVICE_COUNT 1
SMOKE_ALL_PASS_HW_DETECT
```

Hardware programming:

```bash
VIVADO_PART=xc7a200tsbg484-1 HW_PART=xc7a200t ./scripts/smoke-test.sh --hardware-program
```

Expected marker:

```text
SMOKE_ALL_PASS_HW_PROGRAM
```

## Limitations

- This repo does not download Vivado or embed AMD credentials.
- This repo does not redistribute AMD/Xilinx proprietary installers, device files, IP, or licenses.
- The installer may still require interactive login and EULA/product selection.
- Board-specific peripherals are not tested. The hardware program test only validates JTAG configuration.
- The included software project targets `xc7a35tcpg236-1` as a small generic Vivado flow test. It is not meant to match your connected board.
- The safe hardware-program test must use a `VIVADO_PART` compatible with your physical FPGA device.

## License

The scripts and documentation in this repo are released under the MIT License. AMD/Xilinx Vivado and related files remain subject to AMD/Xilinx terms.

## Session Worklog

These are the concrete actions that led to the verified setup:

1. Installed Vivado under `~/Xilinx/<version>/Vivado`; the repo default is now `2023.1`.
2. Confirmed the Vivado BASIC license was detected.
3. Switched x86_64 execution from QEMU to Parallels Rosetta by masking `qemu-x86_64`.
4. Installed `amd64` runtime libraries and x86_64 cross compilers.
5. Created `~/.local/bin/vivado`, which sources `settings64.sh` and prepends x86_64 compiler wrappers.
6. Added `~/.local/xilinx-x86_64-tools/gcc` and `g++`.
7. Added system compiler/linker shims for XSim compatibility.
8. Created a desktop entry for Vivado GUI.
9. Ran GUI launch test successfully.
10. Ran simulation, synthesis, implementation, bitstream, and IP generation smoke tests.
11. Installed Xilinx/Digilent udev rules for JTAG cable access.
12. Detected the connected Digilent JTAG target and `xc7a200t` device.
13. Generated a safe no-external-IO `xc7a200t` bitstream.
14. Programmed the FPGA over JTAG successfully.

## Publish To GitHub

```bash
git init
git add .
git commit -m "Add Vivado Parallels ARM64 Rosetta installer"
git branch -M main
git remote add origin git@github.com:Maotechh/vivado-parallels-arm64-rosetta.git
git push -u origin main
```
