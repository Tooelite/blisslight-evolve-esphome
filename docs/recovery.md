# Recovery

## Prepare Linux

```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip usbutils
bash scripts/setup-linux.sh
```

Check the installed flashing CLI with `.venv/bin/ltchiptool flash write --help`.

## Verify image

```bash
python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

Expected: 2,097,152 bytes and SHA-256 `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`.

## Connect adapter

Follow [wiring.md](wiring.md). With the device disconnected, verify the FT232 adapter and Linux serial port. Confirm the chip responds to a read-only identification operation before attempting any write.

## Flash

**Not enabled.** First verify the image layout, protected/device-specific regions, flash offsets and tool input format. Obtain explicit authorization for writing. `scripts/recovery-flash.sh` currently validates the image and stops.

## Validate

After an authorized flash, check boot, projector output, buttons, motor, Wi-Fi and behavior after a power cycle. Save the serial log if anything fails.
