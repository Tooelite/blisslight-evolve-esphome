# BlissLights Evolve Recovery

BK7231N, 2 MiB flash. USB-UART adapter: Waveshare 6170.

```bash
sudo apt-get install -y python3-venv python3-pip usbutils
bash scripts/setup-linux.sh
python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

[Serial connection](docs/wiring.md) | [Recovery](docs/recovery.md) | [Troubleshooting](docs/troubleshooting.md)

The recovery image is not included. Do not write the full foreign-device dump without checking its flash regions.
