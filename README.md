# ESPHome for BlissLights Evolve

<a href="https://esphome.io/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="images/esphome-logo-on-dark.svg">
    <img src="images/esphome-logo-on-light.svg" alt="ESPHome" width="160">
  </picture>
</a>

An independent ESPHome project for the BlissLights Evolve **SKY-EVOLVE-B-RCWB** with a **Tuya CBU (BK7231N)** module. It lets you control the RGBW nebula, laser and rotation over your local network using Home Assistant.

[![Project license: MIT](images/badge-license-mit.svg)](LICENSE)
[![Firmware: ESPHome](images/badge-firmware-esphome.svg)](https://esphome.io/)
[![Platform: LibreTiny](images/badge-platform-libretiny.svg)](docs/build.md#reference-toolchain)

**Android app in development.** I’m building a companion app for anyone who wants to control the projector directly over their local network without setting up Home Assistant.

<img src="images/galaxy-evolve.png" alt="BlissLights Evolve projector" width="680">

## Get started

1. <img src="images/esphome-logomark.svg" width="24" height="24" alt="ESPHome">&nbsp;&nbsp; **Build the firmware.** Follow the guide to prepare your private configuration and build the firmware. [Build guide](docs/build.md)
2. <img src="images/ltchiptool-icon.png" width="24" height="24" alt="">&nbsp;&nbsp; **Install and verify with ltchiptool.** Read the flashing and safety instructions before opening the projector. [Flashing guide](docs/flash.md)
3. <img src="images/home-assistant-logo.svg" width="24" height="24" alt="">&nbsp;&nbsp; **Connect to Home Assistant.** Add the projector through the ESPHome integration. Start here if ESPHome is already installed. [Connection guide](docs/connect.md)

Already running ESPHome? See how to build, upload and verify an update over Wi-Fi. [OTA update guide](docs/ota.md)

## Reference

- GPIO assignments, adapter connections and PCB photographs. [Hardware and UART wiring](docs/wiring.md)
- Wi-Fi, firmware verification and logging. [Troubleshooting](docs/troubleshooting.md)
- Restore the original firmware from a complete raw flash image. [Recovery guide](docs/recovery.md)
- Review firmware changes by version. [Changelog](CHANGELOG.md)

## License

The [MIT License](LICENSE) applies to Tooelite's original contributions to the ESPHome configuration and documentation in this repository.

Third-party material retains its own terms. This includes the configuration contributed by Dawk323, the original firmware archive in `firmware/recovery/`, the ESPHome logos and other third-party images.

## Credits

[Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html) provided the ESPHome configuration and original firmware reference. [helge1](https://www.elektroda.com/rtvforum/topic3984240.html#21136263) contributed configuration feedback.

The BlissLights and Sky Lite Evolve names identify the hardware covered by this independent project. Rights to the BlissLights branding and original manufacturer firmware remain with their respective holders.

The ESPHome and Home Assistant logos are trademarks of the Open Home Foundation. [Official brand assets](https://github.com/OpenHomeFoundation/brand-assets)

The ltchiptool icon comes from Kuba Szczodrzyński’s ltchiptool project. [Original icon](https://github.com/libretiny-eu/ltchiptool/blob/f3d3af8dd963008f22a31017be84239b4020c19b/ltchiptool/gui/ltchiptool.ico) · [ltchiptool license](images/ltchiptool-LICENSE.txt)
