# BlissLights Evolve — Recovery

Restore a BlissLights Evolve (BK7231N, 2 MiB flash) using a verified recovery image and a USB–UART adapter.

## Quick start

1. Install Debian prerequisites: `sudo apt-get install python3-venv python3-pip usbutils`.
2. Run `bash scripts/setup-linux.sh`.
3. Place the recovery binary at `firmware/recovery/recovery-image.bin`.
4. Run `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.
5. Verify the adapter, wiring and power setup in [wiring](docs/wiring.md).
6. Follow [recovery](docs/recovery.md). **Flashing is disabled until the full-image layout and target-specific data have been verified.**

## Files

- `firmware/recovery/`: recovery binary
- `scripts/`: Linux setup and image validation
- `docs/wiring.md`: USB–UART wiring checks
- `docs/recovery.md`: recovery procedure
- `images/`: board photographs

**Current limitation:** The recovery binary and verified board photographs have not yet been transferred into this repository.
