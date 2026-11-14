# Waveshare 6170 : serial setup and wiring (Debian)

## 1. Configure the FT232 adapter

**Disconnect the projector before configuring the adapter.**

1. Adapter model: **Waveshare 6170 FT232 USB-UART, USB-A**. Check the PCB revision and its printed jumper labels against the corresponding Waveshare 6170 documentation before connecting. **FT232 and USB ID `0403:6001` identify the USB-UART chip, not the board model.** Do not use jumper positions or pin numbering from another model.
2. Set the adapter's **UART I/O voltage to 3.3 V** *only if the actual adapter provides a selectable 3.3 V logic level and the projector's UART level has been verified as 3.3 V*. On boards with separate VCC and VCCIO settings, the relevant setting is **VCCIO / UART logic**, not merely the supply output. If the jumper labels or measured logic voltage are uncertain, stop.
3. Select **TTL UART**, not RS-232 voltage levels. Do not use 5 V UART logic on an unverified 3.3 V target.
4. Leave **VCC, 3V3 and 5V supply outputs disconnected** from the projector until its power supply arrangement has been independently established.
5. Use **TXD, RXD and GND** only. Hardware flow control **RTS/CTS is disabled**; do not connect RTS/CTS or DTR unless a verified boot/reset procedure requires them.
6. Serial framing for the **adapter-only loopback**: **115200 baud, 8 data bits, no parity, 1 stop bit, no flow control (115200 8N1)**. The BK7231N bootloader flashing tool may choose its own baud rate; do not force the loopback rate onto flashing commands without checking the tool.

## 2. Connect the FT232 to Debian

Plug the FT232 into USB **without the projector attached**.

```bash
lsusb -d 0403:6001
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
dmesg | tail -n 30
```

The device path may differ from `/dev/ttyUSB0`.

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

Connect by verified signal labels, not by an assumed connector order. A physical pin-numbered drawing must be based on the actual hardware.

**BK7231N-specific UART1:** TXD of the FT232 connects to **RX1/P10 (GPIO10)**; RXD of the FT232 connects to **TX1/P11 (GPIO11)**. The physical CBU pads must be positively identified on the actual projector; pin names alone do not establish the location of accessible test pads.

**CEN/reset is essential for entering the download bootloader.** With safe 3.3 V UART logic and power already established, start the ltchiptool connect/flash-info command and **momentarily short the verified CEN/reset pad to GND, then release**. This resets the BK7231N while the serial loader is waiting. Do **not** permanently short CEN, randomly probe pads, bridge power rails, or infer CEN from an unverified photo. The proven manual procedure requires no FT232 RTS/CTS/DTR wiring. When link fails, stop and check the reset/power sequence rather than forcing writes.

The target is a BlissLights Evolve with a CBU/BK7231N and 2 MiB flash. Disconnect all power before attaching leads. Confirm a safe power/reset procedure before attempting a read-only bootloader handshake. **Do not flash until wiring and power are verified.**

## 5. Confirm the previously successful flashing tool

Prefer the **same installed executable** used for the earlier successful UART write (not an unpinned, freshly installed substitute):

```bash
~/esphome-env/bin/python -m pip show ltchiptool bk7231tools
~/esphome-env/bin/ltchiptool flash write --help
~/esphome-env/bin/ltchiptool flash info --help
```

Once the projector is safely connected and the CEN reset procedure is understood, the **read-only identification** command is:

```bash
~/esphome-env/bin/ltchiptool flash info bk7231n -d /dev/ttyUSB0
```

Require BK7231N and 2 MiB. Do not post full chip-info logs publicly; they can include chip IDs or security-related data. The full **raw BIN** restore command and its destructive consequences are documented separately in [recovery.md](recovery.md). **No write command is authorized by this document.**
