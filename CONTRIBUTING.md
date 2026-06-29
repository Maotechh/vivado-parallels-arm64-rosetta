# Contributing

Contributions should keep this project focused on the ARM64 Parallels/Rosetta Vivado workflow.

## Before Opening a PR

Run:

```bash
./scripts/validate.sh
```

If Vivado is installed, also run:

```bash
./scripts/smoke-test.sh --software
```

For hardware-related changes, include the board/cable, `lsusb` output, Vivado version, and whether `--hardware-detect` or `--hardware-program` passed.

## Scope

Useful contributions include:

- Fixes for AMD installer layout changes.
- Dependency updates for new Ubuntu releases.
- Better Rosetta/binfmt detection.
- Safer smoke tests and clearer diagnostics.
- Documentation for verified Vivado, Ubuntu, Parallels, and board combinations.

Out of scope:

- Redistributing AMD/Xilinx installers or device files.
- Automating AMD account login or export-control checks.
- Embedding credentials, license files, or proprietary artifacts.
