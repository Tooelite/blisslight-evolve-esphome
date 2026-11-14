# BlissLights Evolve : Recovery

BK7231N (2 MiB) recovery using a verified community firmware image and Waveshare FT232 USB-UART adapter.

## Linux

```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip usbutils
bash scripts/setup-linux.sh
python3 scripts/check-image.py firmware/recovery/recovery-image.bin
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0
```

- [FT232 configuration, Debian serial port and Dupont wiring](docs/wiring.md)
- [Recovery steps](docs/recovery.md)
- [Troubleshooting](docs/troubleshooting.md)

**Not ready to flash:** the binary is not yet in this repository; board-specific pad mapping, power/reset procedure and full-image flash layout remain unverified.
