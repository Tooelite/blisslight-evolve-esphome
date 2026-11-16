# Flash ESPHome firmware

Target: BlissLights Evolve SKY-EVOLVE-B-RCWB (Tuya CBU / BK7231N). Adapter: Waveshare FT232 USB UART Board (Type A, SKU 6170), 3.3 V TTL.

## Power supply - required

**Use the projector's original power adapter for the PCB.** The Waveshare FT232 USB UART Board (Type A, SKU 6170) cannot provide sufficient current to power the projector PCB. Its 3.3 V jumper configures UART logic levels only. **Do not connect FT232 VCCIO, 3V3 or 5V to the PCB power pins.** Connect only TXD, RXD and a common GND, plus the momentary GND-to-CEN reset bridge. Disconnect power before changing wiring.

## Disconnect the laser

The manufacturer's rear label identifies this unit as a **Class 2 laser product** (IEC 60825-1 Ed. 3, 2014; diode laser, maximum output <1 mW).

**Completely disconnect the laser module from the main PCB before powering the opened device or flashing firmware.** Remove power before unplugging it, insulate the disconnected connector, and keep it unplugged during flashing and initial tests. Software-off and motor disconnection do not provide equivalent electrical isolation. Identify the actual laser connection on the hardware; do not infer it from wire colors.

Serial flashing is possible with the laser module disconnected. Reconnect only after the other functions have been verified and the enclosure can be safely closed.

## Wiring

Refer to the [PCB photographs and breadboard layout](wiring.md#pcb-connections).

| PCB pad | PCB wire to breadboard | FT232 wire from breadboard |
| --- | --- | --- |
| RX | 6A (red) | 6E to TXD |
| TX | 8A (brown/gray) | 8E to RXD |
| GND | 10A (black) | 10E to GND |
| Reset / CEN | 12A | No direct FT232 connection |
| 3V3 | Not connected | Not connected |

For reset, briefly bridge **10B (GND)** to **12B (CEN)**, then remove the bridge. Each breadboard row A-E is internally connected.

Use the projector's normal power supply. Never power it from FT232 VCCIO. Verify that the FT232 jumper selects 3V3 and that the UART voltage is 3.3 V. Remove any FT232 TXD-RXD loopback wire before connecting the PCB.

## Flash sequence

1. **Prepare:** Disconnect all power, unplug the laser and wire the PCB and Waveshare **according to the table above**. Check the UF2 image and serial port.
2. **Power on:** Connect the Waveshare to the PC via USB, then connect the PCB to its **original power adapter**.
3. **Flash:** Start `ltchiptool`; when it waits for the chip, briefly bridge **10B to 12B** and remove the bridge. Do not interrupt the transfer.
4. **Verify:** The UF2 writer boots the application after completion. Leave the laser disconnected and verify the router/API status. A deliberate power-cycle test is a separate verification step.

Use the [current build](build.md), record its SHA-256 and check its UF2 metadata before writing. Commands assume an existing `ltchiptool` installation on PATH; otherwise use its actual executable path. Replace `/dev/ttyUSB0` with the verified adapter port.

```bash
ltchiptool uf2 info firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
sha256sum firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
ltchiptool flash write -c -d /dev/ttyUSB0 firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
```

The last command writes device flash. Run it only after explicitly deciding to flash the checked image. `-c` enables data verification. The official UF2 writer boots the firmware after writing; no separate erase command or raw start address is needed. If linking waits, briefly bridge **10B (GND)** to **12B (CEN)** and release it.

## Verify after first boot

With the laser still disconnected, check the serial boot messages if available, configured Wi-Fi, ESPHome API, button, non-laser outputs and operation after a power cycle. The supplied final configuration disables normal ESPHome logs; confirm the running build through the encrypted API instead. A successful write alone does not establish that all firmware functions work. Do not energize an exposed laser or reconnect its cable during open-enclosure tests.

If `ltchiptool` cannot connect, first check that the original power adapter is on, UART TX/RX are crossed, a common GND is present, and the CEN bridge was removed after the short reset. If the chip identifies as something other than BK7231N, or the tool reports repeated CRC errors or unexpected flash offsets, **stop** rather than retrying a write with guessed settings. Never use full-raw-flash offsets for an ESPHome UF2.

References: [LibreTiny CBU](https://docs.libretiny.eu/boards/cbu/), [Beken serial flashing](https://docs.libretiny.eu/docs/platform/beken-72xx/), [ltchiptool](https://docs.libretiny.eu/docs/flashing/tools/ltchiptool/).
