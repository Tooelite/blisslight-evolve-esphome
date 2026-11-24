# BlissLights Sky Lite Evolve

The Evolve configuration covers model **`SKY-EVOLVE-B-RCWB`** with a **Tuya CBU / BK7231N** module. It exposes the RGBW nebula, laser and rotation over the local network. [ESPHome configuration](../../firmware/esphome/galaxy-evolve-v0.3-dev.yaml) · [LibreTiny CBU board](https://docs.libretiny.eu/boards/cbu/)

## Installation and updates

- Build the Evolve firmware with your local configuration. [Build guide](../build.md)
- Install ESPHome over UART using the Evolve wiring. [Flashing guide](../flash.md) · [Hardware and UART wiring](../wiring.md)
- Add the projector to Home Assistant once it is on Wi-Fi. [Connection guide](../connect.md)
- Update an existing ESPHome installation over Wi-Fi. [OTA update guide](../ota.md)
- Check Wi-Fi, firmware and logging. [Troubleshooting](../troubleshooting.md)
- Restore original Evolve firmware from a complete raw flash image. [Recovery guide](../recovery.md) · [Firmware archive](../../firmware/recovery/README.md)
- Review firmware changes by version. [Changelog](../../CHANGELOG.md)

## Related model

**Original Sky Lite (`900-00047_A`, Blue Stars / Blue Cloud).** BlissLights documents local button controls and introduced app control with the Sky Lite 2.0. The first-generation model has no documented Wi-Fi interface. [Model manual](https://manualsfile.com/product/p1l6m5q97ns.html) · [BlissLights model comparison](https://blisslights.com/blogs/blisslights/sky-lite-2-0-vs-evolve-best-galaxy-lights)

To assess a direct ESPHome port for the original Sky Lite, identify its controller and board revision and check whether ESPHome supports that controller. The model label alone does not provide those details.

An ESPHome smart plug can switch power to the original Sky Lite. Its factory firmware determines what happens at power-up, and the device buttons still control brightness and effects. [Official Sky Lite manual](https://cdn.shopify.com/s/files/1/0336/3763/0092/files/SKYLite_MULTI_additional_languages.pdf?v=1726783836#page=5)

[All projectors](../../README.md#projectors)
