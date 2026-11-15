# BlissLights Evolve: ESPHome and Serial Recovery

Firmware sources, build tools, wiring and serial recovery instructions for the **BlissLights Evolve SKY-EVOLVE-B-RCWB**, based on **Tuya CBU / BK7231N** with **2 MiB flash**.

## Firmware options

| Path | Purpose |
| --- | --- |
| [ESPHome](docs/build.md) | Build the RGBW, star laser, motor, button and effects configuration as a UF2 application image |
| [Original recovery](docs/recovery.md) | Restore a complete raw 2 MiB image including bootloader and device storage |

See [Waveshare FT232 wiring](docs/wiring.md) and [troubleshooting](docs/troubleshooting.md).

## Pin mapping

| Function | BK7231N / CBU |
| --- | --- |
| RGBW LEDs | GPIO6 / GPIO26 / GPIO24 / GPIO9 |
| Star laser | GPIO8 |
| Motor | GPIO7 |
| Button | GPIO14 |
| Status LED | GPIO0 |
| UART1 RX / TX | GPIO10 / GPIO11 |

All build scripts and the [ESPHome source YAML](firmware/esphome/galaxy-evolve-2024-v0.1.yaml) are maintained in **this repository**.

**Image formats are not interchangeable.** An ESPHome UF2 is not a complete raw flash dump. A full raw-image restore overwrites the bootloader and device-specific data.

## Credits

Thank you to **[Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html)** for sharing the Evolve firmware dump and ESPHome configuration, and to **helge1** for reporting practical use of the configuration.

**Redistribution:** The archived manufacturer firmware may contain proprietary material and device-specific information. Attribution does not establish redistribution rights; review licensing and sensitive data before making this repository public.

See [CHANGELOG.md](CHANGELOG.md).
