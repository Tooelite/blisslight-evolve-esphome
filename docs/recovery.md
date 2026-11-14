# Recovery steps – full 2 MiB stock BIN using the proven FT232/UART path

**Status: procedure established from source code; full-BIN write and device recovery NOT tested or authorized.**

## 1. Source image and preflight

The recovery source is the complete community BK7231N stock firmware image from another Evolve projector, **not an ESPHome UF2** and **not a backup of this exact projector**.

- Private source repository: `Tooelite/bliss-evolve-android`
- Archive: `firmware/references/evolve-reference-firmware-bk7231n-v1.0.tar.gz`
- Original dump: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`
- Extract the binary locally as `firmware/recovery/recovery-image.bin` (never commit it to this public repository).
- Required length: **2,097,152 bytes / 0x200000**.
- Required SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`.

```bash
python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

**STOP** if the checksum or length differs. This check establishes image identity **only**; it does not establish compatibility or permission to flash.

## 2. Reuse the successful UART transport and reset

The previously successful host-to-chip **write** used `~/esphome-env/bin/ltchiptool flash write -d /dev/ttyUSB0 -c ...firmware.uf2`. This demonstrates the FT232/UART link and BK7231N download channel; it does **not** prove that either the earlier UF2 or this foreign BIN runs successfully.

Use the **same known working `ltchiptool` installation** instead of silently installing a newer one. Check the installed options and package version. Do not run the optional unpinned setup script as a substitute for preserving the proven toolchain.

```bash
~/esphome-env/bin/python -m pip show ltchiptool bk7231tools
~/esphome-env/bin/ltchiptool flash write --help
~/esphome-env/bin/ltchiptool flash info --help
```

Connect only after checking the real PCB: FT232 TXD → BK7231N RX1 (GPIO10/P10); FT232 RXD → TX1 (GPIO11/P11); common GND. Verify **3.3 V UART logic** and an independent, safe power arrangement; the FT232 supply output must not be presumed suitable. See [wiring.md](wiring.md).

For download-mode handshake, begin the `ltchiptool` connection attempt and **momentarily pull the correctly identified CEN/reset pin to GND, then release it**. Do not keep CEN grounded or guess its pad location. No RTS/CTS/DTR connection is needed for the documented manual-reset path.

Check the actual device and chip capacity **without writing**:

```bash
~/esphome-env/bin/ltchiptool flash info bk7231n -d /dev/ttyUSB0
```

Require chip **BK7231N** and flash size **2 MiB**. If those differ, STOP.

## 3. Critical full-image decision – do not skip

The command below would replace **every sector, 0x000000–0x1FFFFF**. In particular:

- `0x000000–0x010FFF`: bootloader. The existing own-device backup does **not** include it.
- Other sectors: application, OTA, factory calibration, identity, storage and settings; exact original-device partition contents are not fully established.
- This BIN comes from a **different** projector. Its identity and calibration data can be different, and its original firmware may rely on unavailable cloud services.

The own-device main and config backups exist separately in the private source repository. Preserving their data versus executing a full factory-image replacement must be an **explicit recovery decision**, not a side effect of an automatic script. Verify the UART bootloader remains accessible and that a recovery fallback is understood. **No write authorization is implied by this document.**

## 4. Full-BIN flash over the same ltchiptool transport – command for review only

A raw flash image is **not** a UF2 package. The existing `ltchiptool flash write` implementation supports raw files when `-f/--family` **and** `-s/--start` are both supplied. That selects the raw path, writes the specified range using `BK7231Serial.program_flash`, and enables per-sector CRC checks through `-c`.

**Destructive: DO NOT execute until the image, wiring, bootloader/reset entry and full-chip replacement are explicitly approved.**

```bash
cd ~/blisslight-evolve-esphome  # replace with the actual clone directory
~/esphome-env/bin/ltchiptool flash write \
  -d /dev/ttyUSB0 \
  -f bk7231n \
  -s 0x000000 \
  -l 0x200000 \
  -c \
  firmware/recovery/recovery-image.bin
```

This is the **full** 2 MiB write: file offset zero → chip address zero. **Do not substitute `-s 0x11000` without a matching `-S 0x11000` and a newly reviewed partial-flash plan.** No UF2 conversion, no automatically generated UF2 and no blind auto-detection.

The underlying BK7231N writer writes 4 KiB sectors, checks CRC on written sectors and retries failed 4 KiB writes up to three times in the examined implementation. If it reports an error or exits unsuccessfully, **STOP**; do not automatically repeat the entire 2 MiB flash. Empty (all-FF) sectors follow an erase-only path, which is not equivalent to independent byte-for-byte readback of the entire chip.

Unlike the UF2 path, the inspected raw-write path does not automatically call the chip reboot routine. After a successful write, release any reset wiring, **manually reboot or safely power-cycle** the device and check that it boots.

## 5. Recovery acceptance

Observe successful boot, stable optical output, buttons/motor, power-cycle behavior and relevant network behavior. A successful CRC-checked write only proves the transfer operation, **not** a functioning original firmware or a working cloud connection.

**Sources for the procedure:** `libretiny-eu/ltchiptool` 4.15.0 implementation (`ltchiptool/commands/flash/write.py`, `ltchiptool/soc/bk72xx/flash.py`), `tuya-cloudcutter/bk7231tools` (`bk7231tools/serial/cmd_hl_flash.py`, `cmd_ll_flash.py`, full-dump restoration examples), and the LibreTiny BK7231N UART/flash-layout documentation.
