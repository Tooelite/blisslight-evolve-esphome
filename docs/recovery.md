# Recovery

1. Install tools: `bash scripts/setup-linux.sh`.
2. Extract `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin` from the source repository archive `firmware/references/evolve-reference-firmware-bk7231n-v1.0.tar.gz` into `firmware/recovery/recovery-image.bin`.
3. Verify: `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.
4. Set up the Waveshare 6170 using [wiring.md](wiring.md).
5. Review the flash layout and device-specific regions before writing. The community dump is from another device.
6. Check `.venv/bin/ltchiptool flash write --help` for the installed tool's syntax and CRC verification options.

Do not flash without an approved image and command.
