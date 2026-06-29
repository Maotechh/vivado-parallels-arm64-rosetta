# Troubleshooting

## `Unsupported architecture: aarch64`

Use the generated wrapper instead of calling Vivado directly:

```bash
~/.local/bin/vivado -version
```

The wrapper adds the `uname -m` shim required by older installer and launcher scripts.

## `xsetup` Rejects the Host

Run the installer through this project instead of executing the downloaded `.bin` directly:

```bash
./install.sh --version <version> --installer ~/Downloads/*<version>*Lin64*.bin
```

The script extracts the installer and runs `xsetup` with the architecture shim.

## Missing `libtinfo.so.5`

Some Vivado releases look for `libtinfo.so.5`. On newer Ubuntu versions only `libtinfo.so.6` may exist. The postinstall wrapper creates:

```text
~/.local/xilinx-x86_64-libs/libtinfo.so.5
```

pointing to the available x86_64 `libtinfo`.

## GUI Starts from Terminal but Not from Launchpad

Regenerate postinstall files:

```bash
./install.sh --version <version> --skip-installer --postinstall-only
```

If the entry still does not appear, refresh the GNOME session:

```bash
gtk-launch vivado-<version>
```

or log out and back in.

## `hw_server` Starts but Finds No Targets

First check that the device is visible inside the VM:

```bash
lsusb
```

If the Digilent or FTDI device is missing, attach it from the Parallels USB menu or replug the cable. Vivado cannot detect a board that Ubuntu cannot see.

If the device is visible, reinstall cable rules:

```bash
./scripts/install-cable-udev.sh
```

Then unplug and replug the cable and retry:

```bash
./scripts/smoke-test.sh --hardware-detect
```

## XSim Fails During Elaboration

Run the full postinstall step with system shims enabled:

```bash
./install.sh --version <version> --skip-installer --smoke
```

If you intentionally disabled system shims with `--no-system-shims`, re-enable them unless you have a different way to force x86_64 compiler/linker tools.

## Restore System Compiler Shims

```bash
./scripts/restore-system-shims.sh
```
