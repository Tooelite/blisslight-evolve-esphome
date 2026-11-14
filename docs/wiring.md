# Waveshare 6170 USB-UART

Adapter: Waveshare 6170, USB-A, FT232. USB ID observed: `0403:6001`. Debian device observed: `/dev/ttyUSB0`.

## Electrical setup

The source repository records **3.37 V at VCCIO and idle TXD** on this adapter. Use 3.3 V TTL UART. Check the physical jumper labels on the Waveshare 6170; do not use a different board's jumper diagram. The projector is powered separately. **Do not connect adapter VCCIO, 3V3 or 5V to the projector.**

## Dupont connections

```text
Waveshare 6170           BlissLights Evolve UART
GND  ------------------> GND
TXD  ------------------> RX
RXD  <------------------ TX
VCCIO / 3V3 / 5V         NOT CONNECTED
RTS / CTS / DTR          NOT CONNECTED
```

Use separate Dupont leads on labeled pins. Connector orientation and PCB pad order must follow the actual hardware, not this signal-level diagram.

## Debian setup

```bash
lsusb -d 0403:6001
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
fuser /dev/ttyUSB0 || true
```

If permission is denied, check `ls -l /dev/ttyUSB0` and `id -nG`. On Debian, add the user to `dialout` only if the device group is `dialout`:

```bash
sudo usermod -aG dialout "$USER"
```

Log out and back in to apply group membership.

## Adapter loopback

Disconnect the projector. Bridge **TXD to RXD** on the Waveshare 6170. Run:

```bash
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0 --timeout 3
```

The test uses **115200 8N1, no flow control**. Exit 0 means PASS, 1 means mismatch, 2 means port error. Remove the TXD/RXD bridge afterward.

## Flash tool

```bash
.venv/bin/ltchiptool flash write --help
```

A successful UART write is documented in the source repository. This is not authorization to flash a foreign full-device image.
