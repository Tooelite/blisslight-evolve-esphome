# Build the ESPHome firmware

Build [`galaxy-evolve-2024-v0.1.yaml`](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml) for the **BlissLights Evolve / Tuya CBU (BK7231N)**. The configuration targets **ESPHome 2024.4.1** and pins LibreTiny to commit `d1386a8e9dcdeed4c50dd0628462b14c9295d304`.

The source includes RGBW outputs, star laser PWM, motor PWM, button controls, status LED and random lighting effects. Its original button behavior is retained.

## Requirements

- Linux with Python 3, `venv`, `pip` and Git.
- Internet access to fetch ESPHome, PlatformIO and SDK dependencies.
- Real local credentials in `firmware/esphome/secrets.yaml`.

The script discovers a suitable Python executable. Some historical dependencies may be incompatible with newer Python releases; resolve a concrete dependency failure rather than silently changing firmware versions.

## 1. Configure secrets

Create `firmware/esphome/secrets.yaml` alongside the firmware YAML:

```yaml
wifi_ssid: "YOUR_WIFI_SSID"
wifi_password: "YOUR_WIFI_PASSWORD"
fallback_ap_password: "YOUR_FALLBACK_AP_PASSWORD"
evolve_2024_api_key: "YOUR_BASE64_API_KEY"
evolve_2024_ota_password: "YOUR_OTA_PASSWORD"
```

Replace all placeholders with real values. The API encryption key must represent **32 bytes**. Generate one locally if necessary:

```bash
python3 -c 'import base64,secrets; print(base64.b64encode(secrets.token_bytes(32)).decode())'
chmod 600 firmware/esphome/secrets.yaml
```

The fallback access point is named `Galaxy-Evolve`. Do not commit or share the secrets file.

## 2. Build from this repository

From the repository root:

```bash
bash scripts/test-build-logging.sh
bash scripts/build-esphome-2024.sh
```

The build script uses the source YAML in **this repository** by default. It checks the source file, shows the exact paths to the YAML and local secrets, and lists all five required keys. **Only the exact interactive response `yes`** permits environment creation, dependency installation, configuration and compilation. All other responses and noninteractive input abort.

After confirmation, the script checks that the secrets file exists and is Git-ignored, selects Python, creates or reuses the isolated `.venv/`, installs/verifies **ESPHome 2024.4.1**, runs configuration and compilation, and reports UF2 candidates with sizes and SHA-256 hashes. **It does not flash the device.**

For a different source directory, pass its absolute path as the first argument. Override the virtual environment or log paths with `ESPHOME_2024_VENV` and `ESPHOME_2024_LOGDIR`.

## 3. Build logs

Dependency installation and compilation progress appear live on the terminal and are captured using `tee`. Logs default to the Git-ignored `.build-logs/` directory.

| File | Contents |
| --- | --- |
| `build-<run-id>.full-private.log` | Complete private transcript, including the resolved configuration |
| `build-<run-id>.review.log` | Automatically redacted review copy; inspect manually before sharing |
| Per-phase logs | Installation, configuration, compilation and UF2 discovery |

Resolved `esphome config` output is stored privately rather than printed, because it may contain credentials. Errors are preserved even when `tee` completes successfully.

**Never publish raw private logs or `secrets.yaml`.** The review copy masks the configured secret values where recognized, but unrelated credentials may remain.

## 4. Inspect before flashing

A successful compile does **not** establish firmware safety or correct device operation. Independently inspect the new UF2 for its BK7231N/CBU target, block addresses, bootloader protection, size, build provenance and SHA-256.

Only a verified UF2 should proceed to the [FT232 serial connection](wiring.md). The UF2 carries its own address mapping; **do not apply [full raw-recovery](recovery.md) offsets** to an ESPHome UF2.

After flashing, verify serial startup, Wi-Fi, RGBW channels, laser, motor, button and a complete power cycle.
