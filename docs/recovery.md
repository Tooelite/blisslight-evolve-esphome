# Recovery procedure — draft v0.1

## 1. Preparation

1. Keep the source firmware immutable. Obtain the original 2 MiB binary from the private archive in `Tooelite/bliss-evolve-android` (see root README). The transfer into this repository is still pending.
2. On Debian install `python3-venv`, `python3-pip`, and `usbutils` using apt, then run `bash scripts/setup-linux.sh`. Record `ltchiptool` and `bk7231tools` versions; this installer is not pinned and has not been tested here.
3. Run `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`. Both the size and SHA-256 must match.

## 2. Hardware and communication

1. Unplug power before connecting wires. Review `docs/wiring.md` and validate the actual board labels against the user's photographs. Never connect mains to a UART adapter.
2. Check the Waveshare FT232 adapter in host-only loopback mode before connecting the projector. The proven source script is `scripts/local/waveshare_ft232_loopback_v1.py` in the original repository.
3. Check `lsusb`, `/dev/serial/by-id/`, permissions and that no other process owns the port. The previous host reported FTDI USB ID `0403:6001`; this is not a guarantee for other adapters.
4. Establish a read-only chip/flash identification handshake first. Do not infer that a serial port alone confirms correct wiring or chip target.

## 3. Mandatory safety gate (OPEN)

The reference image comes from another projector. Map its bootloader, application, configuration and identity regions and compare with the accessible target data. The original target boot region `0x000000–0x010FFF` was not recovered in the documented backup. Decide whether to preserve or replace each region, and confirm the actual `ltchiptool` input format and offsets. **Do not flash a complete foreign dump by default.**

## 4. Writing and verification (NOT YET AUTHORIZED)

The only previously successful *write operation* used UART/FT232 and `ltchiptool flash write` with a different reduced ESPHome 2026 image. The documented `-c` option provides CRC checks of written 4 KiB sectors and retries failed sectors up to three times in that implementation. Confirm that the installed tool really supports these semantics before adopting them. No full-readback or unconditional full reflash is planned. Do not copy the earlier write command without checking format and layout.

`bash scripts/recovery-flash.sh` currently performs only the image checksum gate and deliberately stops. A real writing step will be implemented after the layout decision and explicit authorization.

## 5. Post-flash validation

Check serial startup, stable boot, projector output, controls, Wi-Fi and power cycling. The earlier transient fallback AP does **not** prove recovery. Record errors and outcomes; never label untested behavior successful.
