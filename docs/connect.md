# Connect to Home Assistant

Use this guide once the projector is running ESPHome and connected to your local Wi-Fi. If the projector still needs firmware, start with the [build guide](build.md) and [flashing guide](flash.md).

## Add the projector

1. Open your router's device list and find the projector's current IP address.
2. In Home Assistant, open **Settings → Devices & services → Add integration → ESPHome**.
3. Enter the projector's IP address and port **6053**.
4. When prompted for the encryption key, use `api.encryption.key` from the private YAML used for that build. The Wi-Fi and OTA passwords have separate purposes. [Home Assistant ESPHome integration](https://www.home-assistant.io/integrations/esphome/)

## Browser access and the fallback network

The supplied configuration has no `web_server`, so the projector's normal network address does not offer a browser control page. The captive portal on the fallback access point is for Wi-Fi setup.

If the router shows a saved device entry but the integration cannot connect, check the current Wi-Fi and API status. [Troubleshooting](troubleshooting.md#confirm-the-running-firmware)
