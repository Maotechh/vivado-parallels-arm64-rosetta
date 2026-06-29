# Verification Notes

This project is version-parameterized. It is not tied to a single Vivado release, but the workflow should be verified after installing the version you intend to use.

## Tested Results

The workflow has been tested on Ubuntu 24.04 ARM64 under Parallels Desktop with Vivado 2026.1 and 2023.2.

Verified software flow:

- Vivado wrapper reports the expected version.
- Vivado GUI launches through Rosetta.
- XSim behavioral simulation prints `SMOKE_SIM_PASS`.
- Project-mode synthesis completes with 0 errors.
- Implementation and bitstream generation complete.
- `clk_wiz` IP catalog lookup, generation, and OOC synthesis complete.

Verified hardware flow on a Digilent FTDI JTAG setup:

- `hw_server` and `cs_server` start.
- JTAG target is detected.
- FPGA device is detected as `xc7a200t`.
- A safe no-external-IO bitstream is generated.
- FPGA programming completes and Vivado reports startup done.

## Local Validation

Run script checks:

```bash
./scripts/validate.sh
```

Run Vivado software smoke:

```bash
./scripts/smoke-test.sh --software
```

Run hardware detection after assigning the USB/JTAG cable to the VM:

```bash
./scripts/smoke-test.sh --hardware-detect
```
