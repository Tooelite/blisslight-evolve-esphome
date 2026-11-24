# Operational checks

These checks cover the [BlissLights Evolve](devices/evolve.md).

Identify the ESPHome version used for the installed firmware. The build guide documents the reference commit and the checks for using a newer version. For checks after installation, see the flashing guide. [Build instructions](build.md) · [First-boot checks](flash.md#verify-after-first-boot)

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

### Build and read UART logs

1. From the repository root, copy the private configuration. This leaves the regular build settings available for reinstalling later.

   ```bash
   DIAG_CONFIG=firmware/esphome/galaxy-evolve-v0.3-dev.diagnostic.local.yaml
   umask 077
   if [ ! -e "$DIAG_CONFIG" ]; then
     cp -- firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml "$DIAG_CONFIG"
   fi
   chmod 600 "$DIAG_CONFIG"
   ```

2. In the diagnostic copy, set `esphome.build_path` to `build/galaxy-lamp-v0.3-dev-diagnostic`. Keep the other `esphome` settings. Replace the `logger` block with:

   ```yaml
   logger:
     hardware_uart: UART1
     baud_rate: 115200
     level: DEBUG
   ```

3. Validate and compile that copy. Use the same ESPHome environment as for the regular build. [Build guide](build.md#validate-and-compile)

   ```bash
   .venv-v0.3-dev/bin/esphome config "$DIAG_CONFIG" > /dev/null
   .venv-v0.3-dev/bin/esphome compile "$DIAG_CONFIG"
   ```

4. Inspect and install the diagnostic UF2 from `firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev-diagnostic/.pioenvs/galaxy-lamp/firmware.uf2`. Use this file as `UF2` in the flashing guide. Keep the laser disconnected while the enclosure is open. [Serial flashing guide](flash.md#check-the-exact-image) · [UART wiring](wiring.md#pcb-connections)
5. With the diagnostic firmware running, read UART1 logs using the same diagnostic YAML. Set `PORT` to the actual adapter port.

   ```bash
   PORT=/dev/ttyUSB0
   .venv-v0.3-dev/bin/esphome logs "$DIAG_CONFIG" --device "$PORT"
   ```

Keep logs private because they can contain credentials. Reinstall the regular UF2 to turn logging off again.
