# Flash ESPHome firmware

Target: BlissLights Evolve SKY-EVOLVE-B-RCWB (Tuya CBU / BK7231N). Adapter: Waveshare FT232 USB UART Board (Type A, SKU 6170), 3.3 V TTL.

## Before connecting the projector

Run terminal commands from the repository root. Install **ltchiptool 4.15.0** using [the build guide](build.md#install-ltchiptool-for-image-inspection-and-serial-flashing), or use an existing installation whose version and command syntax you have checked:

```bash
command -v ltchiptool
ltchiptool --version
ltchiptool flash write --help
```

Keep the checked UF2, its recorded SHA-256 and the matching private configuration backed up. Do not flash the public placeholder configuration. If preserving the previous device installation matters, keep a verified backup of that device before overwriting it. The [community recovery reference](recovery.md) comes from another projector and is not a backup of your device identity or settings.

Plug in the USB adapter with the projector disconnected and identify its port:

```bash
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
```

Select the entry belonging to your adapter, checking which entry disappears and reappears when unplugging/replugging the adapter if necessary. Prefer its stable `/dev/serial/by-id/…` path when available. USB detection alone does not verify UART voltage or PCB wiring.

Set `PORT` to that actual path. The example below is only valid if your adapter was identified as `/dev/ttyUSB0`:

```bash
PORT=/dev/ttyUSB0
ls -l "$PORT"
id
fuser "$PORT"
```

Close ESPHome log viewers, serial terminals and any other process using that port before flashing. `fuser` normally exits with status 1 when it finds no user; if the command is unavailable, install Debian's `psmisc` package or check port use with your existing system tools. For `Permission denied`, inspect the serial device's group and your group membership. Debian commonly uses `dialout`; obtain the appropriate group access and log in again before retrying. Do not solve this by running the whole toolchain as root or making the port writable to everyone.

## Power supply - required

**Use the projector's original power adapter for the PCB.** The Waveshare FT232 USB UART Board (Type A, SKU 6170) cannot provide sufficient current to power the projector PCB. Its 3.3 V jumper configures UART logic levels only. **Do not connect FT232 VCCIO, 3V3 or 5V to the PCB power pins.** Connect only TXD, RXD and a common GND, plus the momentary GND-to-CEN reset bridge. Disconnect power before changing wiring.

## Disconnect the laser

The manufacturer's rear label identifies the projector as a **Class 2 laser product** (IEC 60825-1 Ed. 3, 2014; diode laser, maximum output <1 mW).

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

### Check the exact image

Use the [current build](build.md). In the same terminal where you set `PORT`, select the exact UF2:

```bash
UF2=firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
test -s "$UF2"
ltchiptool flash file "$UF2"
ltchiptool uf2 info "$UF2"
sha256sum "$UF2"
```

Stop if the file is missing or any check fails. Require a recognized UF2, family **BK7231N**, board **cbu** and LibreTiny **1.14.0** metadata. Compare the SHA-256 against the value recorded for this exact private build or backup; merely printing a hash does not establish that it is the intended image. Do not rebuild or replace the file between this check and writing. Both ltchiptool commands above inspect the file without contacting the device.

### Write and verify the transfer

After checking the image and completing the wiring/power steps above, explicitly decide to flash. Then run:

```bash
ltchiptool flash write -c -d "$PORT" -t 60 "$UF2"
```

When the tool waits to link, briefly bridge **10B (GND)** to **12B (CEN)** and release it. CEN must not remain grounded. Do not reset, remove power or disconnect the adapter during writing or verification.

`-d` selects the checked adapter, `-c` enables the tool's hash/CRC checks and `-t 60` allows 60 seconds for the initial chip connection. This timeout is unrelated to Wi-Fi association after boot. Baud rates are selected by the tool; no manual rate override is required for this procedure. UF2 supplies the target layout: do not add raw offsets, a transfer length or a separate erase command.

Require completion with **exit status 0 and no reported write/verification error**. Preserve the image hash and transfer result privately. These checks are not a complete independent flash readback and do not establish boot or Wi-Fi success. The official UF2 writer starts the application after writing; a separate manual reset is normally unnecessary.

## Verify after first boot

Keep the laser disconnected throughout open-enclosure checks.

1. Check that the router reports a **currently connected** device and its current IP, not just a saved entry. Keep the configured 2.4 GHz network available. Do not assume a fixed boot-to-connection time; confirm connectivity using the router and encrypted API.
2. Connect through the encrypted ESPHome API, for example using [Home Assistant as described in the README](../README.md#connect-with-home-assistant). Use the API key from the matching private YAML. Where available, compare reported firmware version/build time with the intended build to distinguish it from an old router entry. The firmware does not provide a normal browser control page.
3. Test RGBW, motor and button separately. A deliberate power-cycle test, repeated starts, OTA and longer observation are separate checks, not implied by a successful transfer. Reconnect the laser only with power disconnected and for operation with the enclosure closed.

The supplied configuration disables normal ESPHome serial/API logging. An empty serial terminal therefore does not prove that boot failed. BootROM/SDK output is separate and not guaranteed silent. Enabling ESPHome logs requires a separately built and flashed diagnostic configuration; see [operational checks](troubleshooting.md#logging).

## If a step fails

- **Port missing or busy:** Recheck the adapter path and close its other users. Resolve permissions before retrying. Do not change PCB wiring while either power source is connected.
- **No chip connection:** Check original power, crossed TX/RX, common GND and the brief CEN bridge after the tool starts waiting. After a connection timeout, start the command again and repeat that handshake; do not reset during an active transfer.
- **Unexpected chip/layout or repeated CRC errors:** Stop. Recheck image, wiring, voltage and power before another write. Do not disable verification or guess flash offsets.
- **Interrupted or failed write:** Firmware completeness is unknown. Keep the checked image and private error output; correct the identified connection/power issue before retrying the same image. An interrupted write is not a reason to erase the whole flash or substitute a foreign raw dump.
- **Transfer succeeds but no WLAN/API:** Investigate the running build and configured network separately using [operational checks](troubleshooting.md). Do not infer a successful application test from the flash result, or change MAC/GPIO/framework settings without evidence.

References: [LibreTiny CBU](https://docs.libretiny.eu/boards/cbu/), [Beken serial flashing](https://docs.libretiny.eu/docs/platform/beken-72xx/), [ltchiptool](https://docs.libretiny.eu/docs/flashing/tools/ltchiptool/).
