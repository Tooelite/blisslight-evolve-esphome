# Waveshare FT232 : serial setup and wiring (Debian)

## 1. Configure the FT232 adapter

**Disconnect the projector before configuring the adapter.**

1. Identify the exact Waveshare board revision and inspect the labels printed beside its voltage selector and UART header. **Do not infer a jumper position from a different FT232 model.**
2. Set the adapter's **UART I/O voltage to 3.3 V** *only if the actual adapter provides a selectable 3.3 V logic level and the projector's UART level has been verified as 3.3 V*. On boards with separate VCC and VCCIO settings, the relevant setting is **VCCIO / UART logic**, not merely the supply output. If the jumper labels or measured logic voltage are uncertain, stop.
3. Select **TTL UART**, not RS-232 voltage levels. Do not use 5 V UART logic on an unverified 3.3 V target.
4. Leave **VCC, 3V3 and 5V supply outputs disconnected** from the projector until its power supply arrangement has been independently established.
5. Use **TXD, RXD and GND** only. Hardware flow control **RTS/CTS is disabled**; do not connect RTS/CTS or DTR unless a verified boot/reset procedure requires them.
6. Serial framing for the **adapter-only loopback**: **115200 baud, 8 data bits, no parity, 1 stop bit, no flow control (115200 8N1)**. The BK7231N bootloader flashing tool may choose its own baud rate; do not force the loopback rate onto flashing commands without checking the tool.

The source repository records a working FT232 serial write path and USB ID `0403:6001`. This does not identify the adapter's jumper layout.

## 2. Connect the FT232 to Debian

Plug the FT232 into USB **without the projector attached**.

```bash
lsusb -d 0403:6001
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
dmesg | tail -n 30
```

The previously observed FTDI USB ID was `0403:6001`; the previously observed device was `/dev/ttyUSB0`. The actual device name may differ.

The Linux kernel driver is normally `ftdi_sio` via `usbserial`. Check it if the port is missing:

```bash
lsmod | grep -E '^(ftdi_sio|usbserial)\b' || true
sudo modprobe ftdi_sio
```

Check access and port ownership:

```bash
id -nG
ls -l /dev/ttyUSB0
fuser /dev/ttyUSB0 || true
```

On Debian, serial devices commonly belong to the `dialout` group. If the device permissions confirm this and your user lacks access:

```bash
sudo usermod -aG dialout "$USER"
```

**Log out and log back in** before retrying; do not use `chmod 666` as a workaround. Close serial monitors or other processes holding the port.

## 3. Test the configured serial connection (adapter only)

With the projector **disconnected**, temporarily connect the FT232 **TXD pin to its RXD pin** using one Dupont jumper; **do not bridge any power pins**.

```bash
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0 --timeout 3
```

The script sets **115200 8N1** with software and RTS/CTS hardware flow control disabled. It sends `BLISS-WAVESHARE-LOOPBACK-12345`, and checks that exactly those bytes return.

| Result | Meaning |
|---|---|
| `PASS`, exit 0 | Adapter TXD/RXD loopback works |
| `FAIL`, exit 1 | Received data differ or are missing |
| Exit 2 | Port, permissions or OS error |

Remove the TXD-RXD bridge before connecting the projector.

## 4. Dupont wiring to the projector

Use individual **2.54 mm Dupont leads** with the connector gender matching the actual adapter header and the verified PCB connection method. Do not force Dupont female sockets onto bare PCB solder pads.

| FT232 header signal | Projector UART signal | Connection |
|---|---|---|
| **GND** | **GND** | Common ground |
| **TXD (output)** | **RX (input)** | Crossed |
| **RXD (input)** | **TX (output)** | Crossed |
| **VCC / 3V3 / 5V** | Not connected | **Do not connect** |
| **RTS / CTS / DTR** | Not connected | **Do not connect** |

Connect by the labels on the actual adapter and the previously used projector UART connections, not by an assumed four-pin connector order. A physical pin-numbered drawing must be based on the actual hardware.

The target is a BlissLights Evolve with a CBU/BK7231N and 2 MiB flash. Disconnect all power before attaching leads. Confirm a safe power/reset procedure before attempting a read-only bootloader handshake. **Do not flash until wiring and power are verified.**

## 5. Confirm the flashing tool

```bash
bash scripts/setup-linux.sh
.venv/bin/ltchiptool --help
.venv/bin/ltchiptool flash --help
.venv/bin/ltchiptool flash write --help
```

Use the installed tool's actual options for serial port, chip identification, reset timing and verification. **No write command is authorized by this document.**
