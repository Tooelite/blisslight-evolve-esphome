# Complete community stock firmware (raw BIN)

Local filename: `recovery-image.bin` (ignored by Git; binary is not distributed here).

- Full raw flash size: **2,097,152 bytes / 0x200000**
- Expected SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`
- Source archive: private `Tooelite/bliss-evolve-android/firmware/references/evolve-reference-firmware-bk7231n-v1.0.tar.gz`
- Original name: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`

Check: `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.

**Recovery format:** this is a **full-chip raw BIN**, not UF2. `ltchiptool flash write` supports raw BIN via explicit family and start address (`-f bk7231n -s 0x0`) over the same UART transport as UF2. Full-image writing **also replaces bootloader and device-specific storage**. Do not run a full write without the checks and explicit approval in [docs/recovery.md](../../docs/recovery.md). No device recovery has yet been demonstrated with this image.
