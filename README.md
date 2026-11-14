# BlissLights Evolve : Recovery

BK7231N (2 MiB) recovery using a SHA-256-identified community firmware image and Waveshare 6170 USB-UART adapter.

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

**Recovery image is not in this repository. Do not flash a foreign full-device dump without reviewing its bootloader, configuration and device-specific regions.**
