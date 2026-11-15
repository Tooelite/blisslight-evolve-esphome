# Waveshare FT232 serial wiring

Use a **Waveshare 6170 FT232 USB-to-UART adapter** with the **BlissLights Evolve Tuya CBU / BK7231N UART1** interface.

## Electrical requirements

- Configure **3.3 V TTL logic** (VCCIO if independently selectable). Do not use 5 V logic or RS-232 voltage levels.
- Supply the projector separately from a suitable power source. **Do not connect the adapter's VCC, 3V3 or 5V power pins** without verifying the target's power requirements.
- Share GND between adapter and target. Leave RTS/CTS/DTR disconnected when using manual CEN reset.
- Disconnect power before changing wiring. Confirm physical pads on the device board; signal labels alone do not establish pad positions.

## Connections

| FT232 pin | BK7231N / CBU | Purpose |
| --- | --- | --- |
| GND | GND | Common reference |
| TXD | RX1 / P10 / GPIO10 | Serial data to the target |
| RXD | TX1 / P11 / GPIO11 | Serial data from the target |
| VCC / 3V3 / 5V | Not connected | Avoid unverified power injection |
| RTS / CTS / DTR | Not connected | No hardware flow control |
| GND, briefly | CEN | Manual reset pulse |

## Inspect and test the adapter

```bash
lsusb -d 0403:6001
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
fuser /dev/ttyUSB0 || true
```

Device names may vary between hosts. An FT232 USB ID does not uniquely establish the board revision or jumper positions.

For an **adapter-only loopback test**, disconnect the projector, temporarily connect adapter TXD to RXD and run:

```bash
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0 --timeout 3
```

Remove the loopback wire before reconnecting the projector.

## Enter the BK7231N bootloader

1. Connect the checked UART lines, common GND and suitable separate power.
2. Start a read-only chip information request:
   ```bash
   ltchiptool flash info bk7231n -d /dev/ttyUSB0
   ```
3. While the tool waits, briefly connect **CEN to GND**, then release it.
4. Confirm BK7231N identity and expected flash capacity before any write.

Do not hold CEN low continuously. A successful serial handshake does not establish that an application image will boot.

Select the corresponding firmware procedure: [ESPHome UF2](build.md) or [complete raw recovery](recovery.md).
