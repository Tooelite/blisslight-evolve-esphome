# Operational checks

Use the [current build instructions](build.md) and the pinned ESPHome commit. Keep the projector on its original power supply and follow the [illustrated UART wiring](wiring.md).

## Confirm the running firmware

Check that the FRITZ!Box or other router reports the projector as **currently connected**, with an IP address. A saved device entry alone is insufficient. An encrypted ESPHome API device-info response can confirm the firmware version, build time and original hardware MAC independently of the router's cached entry.

The supplied configuration uses `wifi.hidden: true` for direct SSID connection. The router SSID need not be hidden. Use a compatible 2.4 GHz network. With multiple access points sharing the SSID, this mode does not perform ESPHome's initial strongest-AP selection.

## Logging

The final YAML disables ESPHome logging (`level: NONE`, `boot_log_level: NONE`, `baud_rate: 0`). It therefore does not provide normal ESPHome serial/API logs. BootROM or SDK output is separate and is not guaranteed silent.

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
