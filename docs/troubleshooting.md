# Operational checks

Identify the ESPHome version used for the installed firmware. The build guide documents the reference commit and the checks for using a newer version. Keep the projector on its original power supply and follow the UART wiring guide. [Build instructions](build.md) · [Illustrated UART wiring](wiring.md)

## Confirm the running firmware

Check that the FRITZ!Box or other router reports the projector as **currently connected**, with an IP address. A saved device entry alone is insufficient. An encrypted ESPHome API device-info response can confirm the firmware version, build time and original hardware MAC independently of the router's cached entry.

## Wi-Fi connection

Use a compatible 2.4 GHz network. The supplied configuration sets `wifi.hidden: true`, which tells ESPHome to connect directly by SSID and skip the initial scan used to select a BSSID and channel. The router can keep broadcasting its SSID. If several access points share the SSID, this mode skips ESPHome's initial scan-based selection of the strongest access point. [ESPHome Wi-Fi documentation](https://esphome.io/components/wifi/#connecting-to-multiple-networks)

## Logging

The standard configuration disables normal ESPHome serial and API logging. The BootROM or SDK may still emit output.

```yaml
logger:
  level: NONE
  boot_log_level: NONE
  baud_rate: 0
```

For a separate diagnostic build, replace the logger block **in a private copy** with:

```yaml
logger:
  hardware_uart: UART1
  baud_rate: 115200
  level: DEBUG
```

First validate and compile this private diagnostic configuration using [the build guide](build.md). It must then be flashed after a separate explicit device-flash decision. Editing the YAML or running `esphome logs` cannot enable logging in the already installed No-Log firmware.

After that diagnostic firmware is installed, UART1 is available on the illustrated PCB TX/RX pads. Use the installed official CLI:

```bash
.venv-v0.3-dev/bin/esphome logs firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml --device /dev/ttyUSB0
```

Use the actual adapter port. Logs can expose credentials; keep them private. Return to the supplied disabled-logging configuration after the diagnostic result is recorded.

## Verification boundaries

Verify Wi-Fi, encrypted API device-info, repeated starts, long-term stability, OTA and projector functions on the target device before treating them as validated. Keep the laser disconnected while the enclosure is open; do not reconnect it to diagnose Wi-Fi.
