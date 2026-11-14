# Waveshare FT232 — Linux wiring and verification

## Hardware

- USB–UART interface: Waveshare FT232, FTDI USB VID:PID `0403:6001` (observed).
- Target: BlissLights Evolve, CBU module / BK7231N, 2 MiB flash.
- Serial device observed: `/dev/ttyUSB0`; use `/dev/serial/by-id/` to find the persistent identifier.
- The **exact PCB test-pad locations and power/reset wiring have not been verified from the available photos**. Do not assume a generic BK7231N module pin diagram identifies the board pads.

## Connection table

| Waveshare FT232 signal | Projector board signal | Requirement |
|---|---|---|
| GND | GND | Common signal ground |
| TXD | UART RX | Cross TX to RX |
| RXD | UART TX | Cross RX to TX |
| VCC / 3V3 / 5V | **Not connected** | Do not power the board from the adapter without a verified power plan |
| RTS / CTS | **Not connected** | Not required for the documented three-wire UART connection |

**Voltage:** The UART logic-level selection on the Waveshare adapter must match the target. Verify it from the actual adapter revision, PCB and measurement before connecting. The presence of a 5 V USB supply does **not** establish safe UART voltage. Disconnect mains power before touching wiring. Do not attach USB–UART pins to mains circuitry.

## 1. Identify the adapter (Debian)

```bash
lsusb
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
python3 --version
```

Expected FTDI USB ID on the previously observed host: `0403:6001`. A different ID does not by itself indicate failure.

## 2. Adapter-only loopback

**Projector disconnected.** Temporarily bridge **FT232 TXD to FT232 RXD**. Leave VCC unconnected.

```bash
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0 --timeout 3
```

The script configures **115200 baud, 8 data bits, no parity, 1 stop bit (8N1)** and transmits `BLISS-WAVESHARE-LOOPBACK-12345`. It compares the received bytes with the sent bytes.

- `PASS` / exit 0: adapter transmit/receive loopback worked.
- `FAIL` / exit 1: no matching loopback; check bridge, port and adapter.
- Exit 2: operating-system/port error.

Remove the TXD–RXD bridge before connecting the projector.

## 3. Connect the projector

With all power disconnected, connect **GND→GND**, **TXD→device RX**, **RXD→device TX** only after the **actual pad locations** and voltage have been confirmed. The correct projector power-up/reset sequence is still unverified in this repository. **Do not attempt flashing until it is documented and checked.**

## 4. Inspect the port

```bash
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB0
fuser /dev/ttyUSB0 || true
.venv/bin/ltchiptool --help
.venv/bin/ltchiptool flash --help
```

Use the installed CLI help to establish read-only chip identification and the required reset timing before any write.

## PCB photographs

Board photos and a **pad-by-pad labeled wiring image** are still missing from this repository. Add them to `images/` only after verifying the actual source files and labels. This is a **blocking hardware requirement**, not a cosmetic omission.
