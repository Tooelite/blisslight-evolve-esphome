# Complete community stock firmware (raw BIN)

Local filename: `recovery-image.bin` (ignored by Git; binary is not distributed here).

- Full raw flash size: **2,097,152 bytes / 0x200000**
- Expected SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`
- Source: locally archived BK7231N Evolve community dump (original filename below); source archive path not published here.
- Original name: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`

Check: `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.

**Recovery format:** this is a 2 MiB **raw BIN**, not UF2. Its size alone does **not** prove a valid embedded bootloader or correct address mapping. The same `ltchiptool flash write` UART transport supports raw BIN with explicit `-f`, `-s`, `-S` and `-l`; preserve the existing bootloader and device-specific data by default. An app-only write may be considered after the dump is dissected and exact byte ranges confirmed. **No full-chip write at `0x000000` is approved.** See [docs/recovery.md](../../docs/recovery.md).
