# Build the ESPHome firmware

Build [`galaxy-evolve-2024-v0.1.yaml`](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml) for the **BlissLights Evolve / Tuya CBU (BK7231N)**. The configuration targets **ESPHome 2024.4.1** and pins LibreTiny to commit `d1386a8e9dcdeed4c50dd0628462b14c9295d304`.

The source includes RGBW outputs, star laser PWM, motor PWM, button controls, status LED and random lighting effects. Its original button behavior is retained.

## Requirements

- Linux with Python 3, `venv` and `pip`. **Git is not required.**
- Internet access to fetch ESPHome, PlatformIO and SDK dependencies.
- Real local credentials in `firmware/esphome/secrets.yaml`.

The script discovers a suitable Python executable. Some historical dependencies may be incompatible with newer Python releases; resolve a concrete dependency failure rather than silently changing firmware versions.

## 1. Local secrets

The tracked [`secrets.example.yaml`](../firmware/esphome/secrets.example.yaml) contains placeholders for the five required keys. On each build, the script **automatically copies the template to `firmware/esphome/secrets.yaml` if that file is missing or empty**. It sets private permissions and never replaces a nonempty secrets file.

The confirmation first shows the secrets file path and all five required keys. After the first exact `yes`, the **actual contents** of `secrets.yaml` are displayed directly on the local terminal (not recorded by `tee`). The script then asks **“Are these settings correct?”** and requires a **second exact `yes`**. Any other response aborts. Edit the generated file before confirming; unchanged template placeholders are rejected even after both confirmations. The API encryption key must represent **32 bytes**. Generate a suitable key locally if necessary:

```bash
python3 -c 'import base64,secrets; print(base64.b64encode(secrets.token_bytes(32)).decode())'
```

The fallback access point is named `Galaxy-Evolve`. Keep `secrets.yaml` private; it is excluded by the supplied `.gitignore` in a Git checkout, but a Git checkout is not required. Never publish or share it.

## 2. Build from this repository

From the repository root:

```bash
bash scripts/test-build-logging.sh
bash scripts/build-esphome-2024.sh
```

The build script uses the source YAML alongside the script's project directory by default. It checks that the YAML exists and is nonempty, shows the paths to the YAML and local secrets, and lists all five required keys. **No Git checkout or fixed YAML hash is required:** the same files can be extracted and built from an ordinary directory. **Both interactive confirmations must be exactly `yes`** before environment creation, dependency installation, configuration or compilation. Other responses and noninteractive input abort.

Before confirmation, the script creates the private secrets file from the tracked template if necessary, without overwriting real values. After confirmation and a placeholder check, it selects Python, creates or reuses the isolated `.venv/`, installs/verifies **ESPHome 2024.4.1**, runs configuration and compilation, and reports UF2 candidates with sizes and SHA-256 hashes. **It does not flash the device.**

For a different source directory, pass its absolute path as the first argument. Override the virtual environment or log paths with `ESPHOME_2024_VENV` and `ESPHOME_2024_LOGDIR`.

## 3. Build logs

Before each run, the script deletes **only its own previous `build-*` logs** from the Git-ignored `.build-logs/` directory. An exclusive lock prevents concurrent builds from deleting one another's logs. Source files, secrets, the virtual environment, and compiled firmware are left untouched. Save or review the previous `review.log` before starting another build, because older run logs are intentionally removed. Dependency installation and compilation progress appear live on the terminal and are captured using `tee`.

| File | Contents |
| --- | --- |
| `build-<run-id>.full-private.log` | Complete private transcript, including the resolved configuration |
| `build-<run-id>.review.log` | Automatically redacted review copy; inspect manually before sharing |
| Per-phase logs | Installation, configuration, compilation and UF2 discovery |

Resolved `esphome config` output is stored privately rather than printed, because it may contain credentials. The explicit secrets review after the first `yes` is shown **only on the controlling terminal** via `/dev/tty`, bypassing `tee`, and does not enter the captured build transcript. **The values remain visible in terminal scrollback; run this only on a trusted local terminal.** Errors are preserved even when `tee` completes successfully.

**Never publish raw private logs or `secrets.yaml`.** The review copy masks the configured secret values where recognized, but unrelated credentials may remain.

## 4. Inspect before flashing

A successful compile does **not** establish firmware safety or correct device operation. Independently inspect the new UF2 for its BK7231N/CBU target, block addresses, bootloader protection, size, build provenance and SHA-256.

Only a verified UF2 should proceed to the [FT232 serial connection](wiring.md). The UF2 carries its own address mapping; **do not apply [full raw-recovery](recovery.md) offsets** to an ESPHome UF2.

After flashing, verify serial startup, Wi-Fi, RGBW channels, laser, motor, button and a complete power cycle.
