# Update ESPHome over Wi-Fi (OTA)

For the **BlissLights Evolve SKY-EVOLVE-B-RCWB** with a **Tuya CBU / BK7231N** module. The installed firmware must support native ESPHome OTA, and the projector must be reachable from the computer running ESPHome.

[Choose the update path](#choose-the-update-path) · [Before uploading](#before-uploading) · [Upload](#upload-the-checked-uf2) · [Verify](#verify-after-restart) · [Recover](#if-ota-fails)

## Choose the update path

1. **Original BlissLights firmware is still installed.** Prepare your private configuration and build the CBU image. Use USB-UART and the CEN reset procedure for the first installation. Once ESPHome with native OTA is installed and reachable, you can update over Wi-Fi. [Build guide](build.md) · [First serial installation](flash.md#before-connecting-the-projector)
2. **ESPHome is installed and you want a newer ESPHome or framework version.** Choose the toolchain, keep `bk72xx.board: cbu` and start from the private YAML for this projector. Record the actual ESPHome, LibreTiny and Beken BDK versions, then build and check the new UF2. [Build and image checks](build.md#validate-and-compile)
3. **ESPHome is installed and you only want to change the YAML.** Edit the private YAML, for example to change the cable button's automation. Keep the same toolchain to isolate the configuration change. Compile and check a new UF2 as above. An already built image still contains the configuration it was compiled with. [Build and image checks](build.md#validate-and-compile)

## How OTA works

ESPHome reads the YAML on your computer and compiles its settings into the firmware image. The YAML stays local. For the reference build (**ESPHome `2026.12.0-dev` and LibreTiny `1.14.0`**), the CLI reads the UF2 and selects the portions needed for OTA. The running firmware checks the transfer, stages the update in the CBU's `download` partition and restarts. The bootloader installs the staged application at restart. [Reference ESPHome uploader](https://github.com/esphome/esphome/blob/602cbff184c105be128a01f8d61994407988a914/esphome/components/libretiny/__init__.py#L704-L720) · [LibreTiny CBU flash layout](https://docs.libretiny.eu/boards/cbu/#flash-memory-map)

## Before uploading

- Check that the projector is currently connected and identify its local IP address. Keep the enclosure closed, use the original power supply and keep its **2.4 GHz Wi-Fi** available through the update and restart. ESPHome's CLI can connect directly over the local network. [Confirm the running firmware](troubleshooting.md#confirm-the-running-firmware)
- Check the configuration used to build the firmware **currently running on the projector**. The project template enables `ota` with `platform: esphome` and uses the BK7231N default port, **TCP 8892**. The template configures an OTA password separately from the API key used for device control. Use the installed firmware's OTA settings to connect. For a first OTA test, keep the installed Wi-Fi and credentials in the new build. If you are deliberately changing OTA credentials, follow ESPHome's migration instructions. [Project YAML](../firmware/esphome/galaxy-evolve-v0.3-dev.yaml#L20-L45) · [ESPHome OTA settings](https://esphome.io/components/ota/esphome/#configuration-variables) · [Changing the OTA password](https://esphome.io/components/ota/esphome/#updating-the-password)
- Keep the previous working CBU image and private YAML available for recovery. Inspect the exact UF2 you intend to upload. Both the command-line build and the graphical Device Builder can produce a UF2. [Build options and UF2 checks](build.md) · [LibreTiny Device Builder download](https://docs.libretiny.eu/docs/projects/esphome/#build-upload)

## Upload the checked UF2

From the repository root, set `PROJECTOR_IP` to the actual local address and `UF2` to the file you inspected. `CONFIG` points to the private configuration for this projector. The executable shown is from the reference build environment. For another supported release, use the corresponding ESPHome executable.

```bash
CONFIG=firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
PROJECTOR_IP=192.0.2.10
UF2=/path/to/checked/firmware.uf2
.venv-v0.3-dev/bin/esphome upload "$CONFIG" --device "$PROJECTOR_IP" --file "$UF2"
```

`upload` sends an existing image. With `--file`, the command also works with an inspected UF2 downloaded from Device Builder. ESPHome's `run` command can build and upload in one step. Use `upload` when you want to inspect the image first. [ESPHome CLI reference](https://esphome.io/guides/cli/#upload-command)

## Verify after restart

1. Wait for ESPHome to report a successful upload. Keep power connected while the projector restarts.
2. Confirm the projector rejoins Wi-Fi and responds on its encrypted ESPHome API. Compare the reported version and build time with the intended build when available. When you changed only YAML, the ESPHome version can stay the same. [Operational checks](troubleshooting.md#confirm-the-running-firmware)
3. Test the behavior that prompted the update. For a button change, exercise the relevant press action and check that the other projector controls still respond.

## If OTA fails

| Symptom | Check |
| --- | --- |
| Connection timeout or refusal | Check the current IP in the router and use the OTA port from the installed build. Confirm the computer can reach the projector on the local network. |
| Authentication error | Use the OTA credentials from the installed firmware. For a password change, follow the migration steps linked above. |
| Image or flash-layout error | Recheck the exact UF2, board `cbu` and framework versions before retrying. Use the [build checks](build.md#inspect-and-record-the-image-before-flashing). |
| Projector keeps restarting | If ESPHome safe mode starts and OTA remains reachable, upload a known-good CBU image. If no OTA service is reachable, use UART recovery. [ESPHome safe mode](https://esphome.io/components/safe_mode/) · [UART instructions](flash.md#before-connecting-the-projector) |

The reference path was checked against the project YAML, ESPHome's CLI and upload implementation, and LibreTiny's CBU flash layout. An end-to-end OTA update on a physical Evolve is still to be verified.
