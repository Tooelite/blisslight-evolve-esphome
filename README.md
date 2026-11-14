# BlissLights Evolve — Community firmware recovery

This repository documents a **proposed** UART recovery procedure for the BlissLights Evolve (CBU/BK7231N, 2 MiB flash) using the complete third-party community firmware dump. It is separate from the ESPHome 2024.4.1 build and flashing work.

**Status: preparation only. No recovery flash has been tested or authorized.** The community image has not yet been copied to this repository. Never treat a successful serial write as proof of successful boot or device operation.

## Source image

- Original filename: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`
- Original size: 2,097,152 bytes
- Original SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`
- Existing private archive: `Tooelite/bliss-evolve-android/firmware/references/evolve-reference-firmware-bk7231n-v1.0.tar.gz`
- Archive SHA-256: `2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37`

See `docs/recovery.md` for the staged workflow and safety gates. **Do not write the full 2 MiB image blindly:** it originated from a different device and may contain device-specific data.

## Repository layout

- `firmware/recovery/`: verified community recovery image (pending transfer)
- `scripts/`: Debian tooling, image checks and flash preparation
- `docs/`: wiring, hardware, recovery procedure and troubleshooting
- `images/`: user-provided board photos (pending verified retrieval)

## Evidence and limitations

The existing project documents an FT232/UART serial write using `ltchiptool`, but it flashed a different, reduced ESPHome 2026 image. The fallback AP was transient and stable operation was **not** established. `ltchiptool flash write -c` provides per-sector CRC verification and selective retries in the documented implementation; installed tool versions and exact CLI behavior must be confirmed before use. No community-image recovery success is claimed.

Source project: https://github.com/Tooelite/bliss-evolve-android
