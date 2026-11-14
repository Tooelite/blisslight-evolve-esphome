# BlissLights Evolve: full-BIN recovery over BK7231N UART

**Goal:** restore a BlissLights Evolve (CBU/BK7231N, 2 MiB flash) from the **complete 2 MiB community stock-firmware dump** using the same FT232/UART/ltchiptool transport that previously transferred an ESPHome UF2 to this projector.

**Important distinction:** the earlier UF2 **write completed**, but stable operation was not demonstrated. Writing the community BIN is technically supported by the same tool in **raw mode**, but has **not yet been tried or approved on this projector**. The community image is from a different unit; it is not a backup of this unit's identity or calibration data.

## Actual recovery path

1. Extract the known 2 MiB BIN locally, then run `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.
2. Use the already proven `~/esphome-env/bin/ltchiptool` on Debian, the Waveshare 6170 FT232, verified RX1/TX1/GND wiring and the **CEN-to-GND reset sequence** to enter the BK7231N download mode.
3. Confirm chip identification and flash size, then review the consequence of replacing **all 2 MiB** (including bootloader and device-specific regions).
4. **Only after separate authorization:** write the raw BIN with explicit BK7231N family, start `0x0`, length `0x200000` and in-write CRC verification. Reboot manually after successful raw write; check stable device operation.

**No UF2 conversion required.** The same `ltchiptool flash write` CLI can accept UF2 or raw BIN; for raw BIN, use explicit `-f bk7231n -s 0x0` to select raw mode.

The exact preparation, **non-writing chip-info command**, proposed full-flash command and stop conditions are in [docs/recovery.md](docs/recovery.md). Physical wiring and CEN reset: [docs/wiring.md](docs/wiring.md).

The raw BIN is **not stored in this public repository**. `firmware/recovery/*.bin` is ignored by Git. Do not commit it or logs containing private device identity information.
