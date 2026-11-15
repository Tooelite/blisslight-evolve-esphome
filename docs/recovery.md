# Recovery steps – full 2 MiB stock BIN using the proven FT232/UART path

**Status (15 Nov 2026): complete BIN hash verified; a bootloader RBL and application scan detected; write ranges and device recovery NOT tested or authorized.**

## 1. Source image and preflight

The recovery source is the complete community BK7231N stock firmware image from another Evolve projector, **not an ESPHome UF2** and **not a backup of this exact projector**.

- Source: a locally archived full-device community dump, originally published for a BK7231N Evolve projector. The archive path on the maintainer's system is deliberately not published here.
- Original dump: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`
- Extract the binary locally as `firmware/recovery/recovery-image.bin` (never commit it to this public repository).
- Required length: **2,097,152 bytes / 0x200000**.
- Required SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`.

```bash
python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

**STOP** if the checksum or length differs. This check establishes image identity **only**; it does not establish bootloader compatibility or permission to flash.

**Mandatory read-only boot/layout evidence:**

```bash
bk7231tools dissect_dump firmware/recovery/recovery-image.bin
```

**Actual result on 15 Nov 2026 (local Debian, read-only):** the extracted 2 MiB image matches the expected SHA-256 exactly. `bk7231tools dissect_dump` (default layout `ota_1`) reports:

```text
RBL containers:
    0x10f9a: bootloader - [encoding_algorithm=NONE, size=0xea20]
Missing app RBL container. Using a scan pattern instead
    0x11000: app - [NO RBL, size=0xdeac0]
Storage partition:
    0x1ee000: 32 KiB - 12 keys
```

**Source-code interpretation:**

- `0x10F9A` is the **RBL header position near the end** of the `0x000000–0x010FFF` boot partition, **not** a bootloader entry address or the beginning of the firmware. The parser validates RBL header CRC and payload CRC before reporting a named, non-null `bootloader` payload. This is strong evidence of intact bootloader content in the foreign file, **not** proof it can run on this specific unit.
- `0x011000` is the app **start specified by the analyzer's default `ota_1` layout**. It is consistent with the earlier UF2 write start, but an independent full-image partition/layout check is still needed. `0xDEAC0` is the CRC-stripped **extracted payload size**, **not** the physical app partition length or the range to write.
- `0x1EE000` marks detected 32 KiB Tuya key-value storage. This independently matches the own-device backup split: boot-region size `0x11000` + main length `0x1DD000` = `0x1EE000`; the original config backup spans `0x1EE000–0x1FFFFF` (length `0x12000`). This validates the **outer backup partition boundary**, not the internal app/OTA partition lengths. The additional end-of-flash bytes are not automatically classified as safe to overwrite. Preserve identity, calibration and settings by default.

**Next read-only step:** independently examine the app's physical CRC-block continuity, padding and partition boundary. Cross-check against the known local main/config backup segmentation and the alternative `ota_big` layout; only then select exact sectors for a possible application-only write. **No full-chip write and no inferred offset shifting.**

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

## 3. Critical bootloader and partition decision – do not skip

**The foreign BIN contains a parsed bootloader RBL with validated header/payload CRC, but runnability and compatibility with this device remain unproven.** A 2 MiB dump containing a valid RBL does not authorize replacing the currently responsive bootloader. **Do not write the full file at chip address `0x000000`.**

- `0x000000–0x010FFF`: the existing, currently responding UART bootloader region. The own-device backups do **not** include it. Preserve this region by default.
- Application region: determine the true start and end offsets from the foreign image and the existing BK7231N layout. The previously successful UF2 transfer began at `0x011000`; this is evidence of the earlier UF2 layout, **not** automatic proof of the foreign BIN's layout.
- Remaining sectors: preserve the original unit's factory calibration, identity, storage and configuration wherever possible. The original backup has a separate main segment (1,953,792 bytes) and config segment (73,728 bytes); these sizes provide a reference, not an unconditional flash map approval.
- If the foreign bootloader is absent, corrupt, nonstandard or unverified, **never** replace the working bootloader with it. If OEM application compatibility with that bootloader is uncertain, stop before the write.

**Do not shift data by 0x11000:** when selecting a partial raw-BIN write from a complete dump, the file skip offset `-S` and target flash start `-s` must refer to the **same original address**. Identify and approve the exact length and affected sectors, then preserve all unselected regions. Do not silently include device-specific configuration in the application write.

## 4. Raw BIN over the same proven ltchiptool transport – no unreviewed full-chip write

A raw flash image is **not** a UF2 package. The existing `ltchiptool flash write` code supports raw-BIN input with explicit chip family (`-f bk7231n`), start address (`-s`) and optional input offset (`-S`) and length (`-l`). CRC verification (`-c`) is implemented in the existing writer.

**No complete `-s 0x000000 -l 0x200000` command is approved or recommended.** A foreign bootloader RBL was detected and CRC-checked, but its compatibility is unknown; overwriting the existing bootloader could disable the working UART recovery path.

After the read-only analysis identifies a suitable app-only range, a reviewed write command must maintain **the original mapping:** file offset = target flash offset for a raw full dump. For example, if a region begins at `0x011000`, both `-s 0x011000` and `-S 0x011000` are needed, and `-l` must equal the specifically approved region length. This is an **illustration of address mapping, not a flash command or approval**. Never invent a range or blindly use the file's full 2 MiB length.

Do not modify, truncate, or repackage the source BIN to 'make' its offsets fit. No UF2 conversion is required; `ltchiptool` already supports raw files. A flash will only be considered after image layout, identity/config preservation, wiring and explicit authorization are established.

The underlying BK7231N writer writes 4 KiB sectors, checks CRC on written sectors and retries failed 4 KiB writes up to three times in the examined implementation. If it reports an error or exits unsuccessfully, **STOP**; do not automatically repeat the entire 2 MiB flash. Empty (all-FF) sectors follow an erase-only path, which is not equivalent to independent byte-for-byte readback of the entire chip.

Unlike the UF2 path, the inspected raw-write path does not automatically call the chip reboot routine. After any **later authorized** write, release any reset wiring, **manually reboot or safely power-cycle** the device and check that it boots.

## 5. Recovery acceptance

Observe successful boot, stable optical output, buttons/motor, power-cycle behavior and relevant network behavior. A successful CRC-checked write only proves the transfer operation, **not** a functioning original firmware or a working cloud connection.

**Sources for the procedure:** `libretiny-eu/ltchiptool` 4.15.0 implementation (`ltchiptool/commands/flash/write.py`, `ltchiptool/soc/bk72xx/flash.py`), `tuya-cloudcutter/bk7231tools` (`bk7231tools/serial/cmd_hl_flash.py`, `cmd_ll_flash.py`, full-dump restoration examples), and the LibreTiny BK7231N UART/flash-layout documentation.
