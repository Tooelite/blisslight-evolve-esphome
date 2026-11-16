# Unofficial ESPHome Firmware for BlissLights Evolve

<img src="images/galaxy-evolve.png" alt="BlissLights Evolve projector" width="680">

ESPHome configuration for the BlissLights Evolve (SKY-EVOLVE-B-RCWB, Tuya CBU / BK7231N). Independent project, not affiliated with BlissLights.

## Current firmware

Use [`galaxy-evolve-v0.3-dev.yaml`](firmware/esphome/galaxy-evolve-v0.3-dev.yaml) with official ESPHome-dev commit **`602cbff184c105be128a01f8d61994407988a914`** (`2026.12.0-dev`). This source selects **LibreTiny 1.14.0 / Beken BDK 3.0.78** through ESPHome's upstream defaults; the YAML does not override the framework.

The configuration uses an SSID-directed Wi-Fi connection:

```yaml
wifi:
  hidden: true
```

This selects ESPHome's direct connection path without an initial scan-based BSSID/channel selection. It does **not** hide the router's network name or require a hidden router SSID. With several access points sharing the SSID, ESPHome does not first select the strongest one from its own scan. The device keeps its original hardware MAC.

ESPHome logging is disabled in the final configuration:

```yaml
logger:
  level: NONE
  boot_log_level: NONE
  baud_rate: 0
```

A private build of this configuration passed validation and compilation, was UART-flashed with data verification, connected to the home Wi-Fi, and answered an encrypted ESPHome API device-info request identifying the new build on **16 November 2026**. Connection time from boot, repeated cold starts, long-term stability, OTA and all projector functions have not been separately validated. CPU/power savings from disabling logging were not measured.

The checked-in YAML contains **placeholders only**. Put credentials in the Git-ignored `.local.yaml` described in the build guide. Firmware binaries also contain credentials and must remain private.

## Connect with Home Assistant

Find the projector's current IP address in the router. In Home Assistant, open **Settings → Devices & services → Add integration → ESPHome**, enter that IP and port **6053**, and supply the encryption key from your private YAML (`api.encryption.key`). This is a different value from the Wi-Fi or OTA password. See the [official integration guide](https://www.home-assistant.io/integrations/esphome/).

The supplied YAML has no `web_server`; the normal home-network IP does not provide a browser control page. The fallback access-point captive portal serves network provisioning.

## Documentation

- [Build the current firmware](docs/build.md)
- [Flash and verify](docs/flash.md)
- [Waveshare FT232 wiring and PCB photographs](docs/wiring.md)
- [Operational checks](docs/troubleshooting.md)
- [Original firmware recovery reference](docs/recovery.md)

## Hardware

| Function | CBU / BK7231N |
| --- | --- |
| RGBW | GPIO6, GPIO26, GPIO24, GPIO9 |
| Laser | GPIO8 |
| Motor | GPIO7 |
| Button | GPIO14 |
| Status LED | GPIO0 |
| UART1 RX / TX | GPIO10 / GPIO11 |

Use the original projector power supply. Keep the laser electrically disconnected while the device is open. An ESPHome UF2 is an application image, not a complete raw flash dump.

## Credits

ESPHome configuration and firmware reference: [Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html); configuration feedback: [helge1](https://www.elektroda.com/rtvforum/topic3984240.html#21136263).

Upstream platform update: [ESPHome #21531](https://github.com/esphome/esphome/pull/21531). Connection option: [ESPHome Wi-Fi documentation](https://esphome.io/components/wifi/#connecting-to-multiple-networks).
