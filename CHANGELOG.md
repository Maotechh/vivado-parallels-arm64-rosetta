# Changelog

## Unreleased

- Reorganized project documentation into a formal README and `docs/` pages.
- Added project validation script and GitHub issue/PR templates.
- Added repository metadata files for editor defaults, line endings, security, and contribution guidance.

## Current

- Supports Vivado installer extraction with an ARM64-safe `uname` shim.
- Supports interactive and batch install flows.
- Detects both `~/Xilinx/<version>/Vivado` and `~/Xilinx/Vivado/<version>` layouts.
- Creates Vivado GUI, XSim, compiler, linker, library, and desktop launch workarounds for Parallels ARM64/Rosetta.
- Provides software, hardware-detect, and hardware-program smoke tests.
