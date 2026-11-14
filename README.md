# BlissLights Evolve: full-BIN recovery over BK7231N UART

**Goal:** restore a BlissLights Evolve (CBU/BK7231N, 2 MiB flash) from the **complete 2 MiB community stock-firmware dump** using the same FT232/UART/ltchiptool transport that previously transferred an ESPHome UF2 to this projector.

**Important distinction:** the earlier UF2 **write completed**, but stable operation was not demonstrated. Writing the community BIN is technically supported by the same tool in **raw mode**, but has **not yet been tried or approved on this projector**. The community image is from a different unit; it is not a backup of this unit's identity or calibration data.

## Actual recovery path

1. Extract the known 2 MiB BIN locally, then run `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.
2. Use the already proven `~/esphome-env/bin/ltchiptool` on Debian, the Waveshare 6170 FT232, verified RX1/TX1/GND wiring and the **CEN-to-GND reset sequence** to enter the BK7231N download mode.
3. **Before any write, inspect the actual contents and offsets of the 2 MiB dump**, including whether a valid bootloader region exists. The size and SHA-256 alone do not establish this. Use the existing read-only `bk7231tools dissect_dump` command.
4. **Preferred recovery design:** preserve the already responding bootloader (`0x000000–0x010FFF`) and preserve own-device configuration wherever possible; write only identified stock application regions at their *original addresses*. The write range must be evidenced and approved before any command is run. Full-chip replacement is an exceptional, separately justified option.

**No UF2 conversion required.** The same `ltchiptool flash write` CLI supports UF2 and raw BIN. For raw BIN, explicit `-f bk7231n -s <validated-target-address>` selects raw mode; when restoring from a full-dump file, the matching input offset must also be supplied with `-S <validated-file-offset>`. **Never shift the firmware data into the wrong flash address.**

The exact preparation, **non-writing chip-info command**, proposed full-flash command and stop conditions are in [docs/recovery.md](docs/recovery.md). Physical wiring and CEN reset: [docs/wiring.md](docs/wiring.md).

The raw BIN is **not stored in this public repository**. `firmware/recovery/*.bin` is ignored by Git. Do not commit it or logs containing private device identity information.
