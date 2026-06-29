# How It Works

Vivado for Linux is distributed as x86_64 binaries. On Ubuntu ARM64 in Parallels Desktop, the binaries can run through Rosetta, but the default system state is not enough for a reliable install.

## Rosetta vs QEMU

The desired x86_64 binfmt entry is:

```text
/proc/sys/fs/binfmt_misc/RosettaLinux
interpreter /media/psf/RosettaLinux/rosetta
```

Some systems also register `qemu-x86_64`. This project masks that handler so Vivado runs through Rosetta:

```text
/etc/binfmt.d/qemu-x86_64.conf -> /dev/null
```

The script avoids restarting `systemd-binfmt` because doing so can remove Parallels' Rosetta registration.

## `uname -m` Shim

Some AMD installer and launcher scripts check:

```bash
uname -m
```

On the guest this returns `aarch64`, even though x86_64 binaries can run through Rosetta. The scripts put a small shim first in `PATH`:

```text
uname -m -> x86_64
```

All other `uname` invocations still call `/usr/bin/uname`.

## Installer Extraction

The downloaded `.bin` wrapper may reject ARM64 before it reaches the real installer. The install script extracts it first:

```bash
bash installer.bin --noexec --target <temp-dir>
```

Then it runs the extracted `xsetup` under the `uname` shim.

## Runtime Dependencies

Ubuntu ARM64 needs a set of `amd64` libraries for x86_64 Vivado tools. The dependency script enables multiarch:

```bash
sudo dpkg --add-architecture amd64
```

It installs x86_64 runtime, compiler, GTK, USB, and FTDI packages used by Vivado, XSim, `hw_server`, and the GUI.

## XSim Compiler and Linker Shims

XSim can invoke host compiler and linker tools while building x86_64 simulation snapshots. On an ARM64 guest, unqualified `gcc`, `g++`, or `ld` can accidentally point to ARM64 tooling.

The postinstall step creates wrappers in:

```text
~/.local/xilinx-x86_64-tools/
```

It can also install backed-up system shims for:

```text
/usr/bin/gcc
/usr/bin/g++
/usr/bin/ld
```

Backups are stored as:

```text
/usr/bin/gcc.vivado-arm64-rosetta-backup
/usr/bin/g++.vivado-arm64-rosetta-backup
/usr/bin/ld.vivado-arm64-rosetta-backup
```

Restore them with:

```bash
./scripts/restore-system-shims.sh
```

## Desktop Launch Quirk

GNOME/GIO desktop launch injects:

```text
GIO_LAUNCHED_DESKTOP_FILE
GIO_LAUNCHED_DESKTOP_FILE_PID
```

In the tested ARM64/Rosetta setup, Vivado GUI could launch from a terminal but crash when launched through a `.desktop` file until those variables were cleared. The generated wrapper unsets them before executing Vivado.
