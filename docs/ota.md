# Update ESPHome over Wi-Fi (OTA)

For the **BlissLights Evolve SKY-EVOLVE-B-RCWB** with a **Tuya CBU / BK7231N** module.

[Choose the update path](#choose-the-update-path) · [Before uploading](#before-uploading) · [Upload](#upload-the-checked-uf2) · [Verify](#verify-after-restart) · [Recover](#if-ota-fails)

## Choose the update path

1. **Original BlissLights firmware.** Build the CBU image from your private YAML. Install ESPHome first over USB-UART using the CEN reset procedure. [Build guide](build.md) · [First serial installation](flash.md#before-connecting-the-projector)
2. **Update ESPHome or the framework.** Keep `bk72xx.board: cbu`, choose the new toolchain and record the ESPHome, LibreTiny and Beken BDK versions it uses. Build and check a new UF2.
3. **Change only the YAML.** Edit your private YAML, for example to change the cable button's action. Keep the same toolchain to isolate the change. Build and check a new UF2.

Paths 2 and 3 use the same OTA procedure once native ESPHome OTA is enabled and reachable. [Build and image checks](build.md#validate-and-compile)

## How OTA works

1. **Build on the computer.** ESPHome compiles the YAML settings into the firmware. The YAML stays local. An existing image contains the settings it was built with.
2. **Send the update.** With the reference ESPHome `2026.12.0-dev` and LibreTiny `1.14.0`, the CLI reads the UF2 and selects the data needed for OTA. [Reference ESPHome uploader](https://github.com/esphome/esphome/blob/602cbff184c105be128a01f8d61994407988a914/esphome/components/libretiny/__init__.py#L704-L720)
3. **Install on restart.** The projector checks the transfer and stages it in the CBU's `download` partition. The bootloader installs the staged application after the restart. [LibreTiny CBU flash layout](https://docs.libretiny.eu/boards/cbu/#flash-memory-map)

## Before uploading

- **Connection.** Find the projector's current IP in the router or through the ESPHome integration. Keep the enclosure closed and the original power supply and 2.4 GHz Wi-Fi available. The CLI connects over the local network. [Confirm the running firmware](troubleshooting.md#confirm-the-running-firmware)
- **OTA port.** Check the YAML used for the installed firmware. The supplied template enables native ESPHome OTA on the BK7231N default port, **TCP 8892**. [Project YAML](../firmware/esphome/galaxy-evolve-v0.3-dev.yaml#L20-L45) · [ESPHome OTA settings](https://esphome.io/components/ota/esphome/#configuration-variables)
- **Credentials.** Connect using the OTA settings of the running firmware. The template has a separate OTA password and API encryption key. For the first test, keep the installed Wi-Fi and credentials in the new build. [Changing the OTA password](https://esphome.io/components/ota/esphome/#updating-the-password)
- **Images.** Keep the previous working CBU image and its private YAML for recovery. Inspect the UF2 you intend to upload, whether built in the CLI or downloaded from Device Builder. [Build options and UF2 checks](build.md) · [Device Builder download](https://docs.libretiny.eu/docs/projects/esphome/#build-upload)

## Upload the checked UF2

Run this from the repository root. Set `PROJECTOR_IP` to the projector's actual IP and `UF2` to the inspected file. Use the ESPHome executable for your chosen toolchain.

```bash
CONFIG=firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
PROJECTOR_IP=192.0.2.10
UF2=/path/to/checked/firmware.uf2
.venv-v0.3-dev/bin/esphome upload "$CONFIG" --device "$PROJECTOR_IP" --file "$UF2"
```

- **`upload`** sends an existing image. Use `--file` to select the exact UF2 you inspected.
- **`run`** builds and uploads in one step. [ESPHome CLI reference](https://esphome.io/guides/cli/)

## Verify after restart

1. Wait for ESPHome to report a successful upload. Keep power connected through the restart.
2. Confirm Wi-Fi and the encrypted ESPHome API are back. Check the version and build time when available. A YAML-only change can keep the same ESPHome version. [Operational checks](troubleshooting.md#confirm-the-running-firmware)
3. Test the behavior you updated. For a button change, check the intended press action and the other projector controls.

## If OTA fails

- **Timeout or connection refused.** Check the current IP, the OTA port from the installed build and local network reachability.
- **Authentication error.** Use the credentials of the running firmware. For a password change, follow the [ESPHome migration steps](https://esphome.io/components/ota/esphome/#updating-the-password).
- **Image or flash-layout error.** Recheck the exact UF2, board `cbu` and framework versions before retrying. [UF2 checks](build.md#inspect-and-record-the-image-before-flashing)
- **Repeated restarts.** If ESPHome safe mode starts and OTA is reachable, upload a known-good CBU image. If OTA is unavailable, use UART. [ESPHome safe mode](https://esphome.io/components/safe_mode/) · [UART instructions](flash.md#before-connecting-the-projector)

The reference path was checked against the project YAML, ESPHome's CLI and upload implementation, and LibreTiny's flash layout. An end-to-end OTA update on a physical Evolve is still to be verified.
