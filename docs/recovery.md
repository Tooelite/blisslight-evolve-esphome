# Restore the complete original firmware

This procedure restores a **complete, unmodified 2 MiB raw flash dump** from another BlissLights Evolve (Tuya CBU / BK7231N). This file is **not** a UF2 application image. Restoration of this reference dump has not been validated on the current device; the working ESPHome installation does not require this procedure.

**Warning:** Disconnect the laser module electrically before powering the opened device or flashing, as described in [flash safety](flash.md). A complete restore replaces the bootloader, firmware, device identity, stored settings and potentially calibration data. The reference image comes from another device and may not work on every hardware revision. Verify the target and source before writing.

## Reference firmware

| Property | Value |
| --- | --- |
| Archive | `firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz` |
| Original BIN | `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin` |
| Raw size | **2,097,152 bytes (`0x200000`)** |
| Raw SHA-256 | `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0` |
| Archive SHA-256 | `2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37` |

The dump contains a CRC-valid bootloader RBL header at `0x10F9A`, an application scan from `0x11000`, and Tuya storage from `0x1EE000`. The analyzer's value **`0xDEAC0` is a CRC-stripped application payload length, not a flash-write length**. Do not crop the raw file, shift its addresses or flash the extracted application data in place of the complete BIN.

Thanks to **[Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html)** for providing the firmware dump. Check redistribution rights and any embedded device-specific data before publishing the archive.

## 1. Extract and verify

From the repository root:

```bash
echo '2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37  firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz' | sha256sum -c -

tar -xOzf firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz \
  'readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin' \
  > firmware/recovery/recovery-image.bin

python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

Only continue if the image checker reports `PASS`. The extracted binary is Git-ignored.

## 2. Identify the target

Follow [FT232 wiring](wiring.md). Use 3.3 V UART I/O, crossed RX/TX, a shared GND and a brief CEN-to-GND reset while `ltchiptool` waits.

```bash
ltchiptool flash info bk7231n -d /dev/ttyUSB0
```

Confirm **BK7231N** and **2 MiB flash**. Stop if either differs.

## 3. Write the complete raw image

Check the installed tool's syntax with `ltchiptool flash write --help` before proceeding:

```bash
ltchiptool flash write \
  -d /dev/ttyUSB0 \
  -f bk7231n \
  -s 0x000000 \
  -S 0x000000 \
  -l 0x200000 \
  -c \
  firmware/recovery/recovery-image.bin
```

| Option | Meaning | Value |
| --- | --- | --- |
| Input | Complete original raw BIN | `recovery-image.bin` |
| `-S` | Source-file offset | `0x000000` |
| `-s` | Target-flash offset | `0x000000` |
| `-l` | Transfer length | `0x200000` |
| `-c` | Sector CRC validation | Enabled |

The CRC checks and retries are **not** equivalent to a complete independent flash readback or proof that the device boots correctly.

## 4. Verify functionality

Keep the laser disconnected during open-enclosure checks of serial boot, RGBW, motor, local controls and Wi-Fi. Evaluate the laser only with the enclosure closed and the electrical precautions in the flash guide observed. Check operation after a power cycle separately. Original cloud functionality may require services that are unavailable.

For an ESPHome UF2, use [the build instructions](build.md). **Never apply raw full-flash offsets to a UF2 image.**
