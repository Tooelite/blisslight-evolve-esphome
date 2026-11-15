# Firmware B – build the complete Evolve image with ESPHome 2024.4.1

**Working procedure v1.2 – 15 November 2026.** This document records the exact build sequence agreed for the next local attempt on Debian. **No ESPHome 2024.4.1 configuration validation, compilation, UF2 verification, or 2024-image flash has succeeded yet.** Update the steps only when the actual local logs justify a correction.

**Current execution workspace:** `~/projekte/bliss-evolve-android` (the older research repository). This guide is maintained in `blisslight-evolve-esphome`, the canonical documentation repository. The firmware YAML is already **byte-identical** in both repositories, so the commands below deliberately keep the working path in the old repository while the first build is being validated. After a proven build, we can promote the checked procedure to run directly in this repository. Do not accidentally compile the obsolete ESPHome 2026 firmware.

## Lean spec v0.1 – scope and status

| Step | Expected outcome | Status |
| --- | --- | --- |
| 1. Source | Full 2024 Evolve YAML preserved | **Verified in Git** |
| 2. Secrets | Real home Wi-Fi, fallback AP, API and OTA settings in local file | **To check on Debian** |
| 3. Environment | Isolated ESPHome 2024.4.1 Python environment | **Not yet confirmed** |
| 4. Build | `esphome config` and `esphome compile` succeed | **Pending** |
| 5. Image QA | Inspect UF2, BK7231N target, flash ranges, size and SHA-256 | **Pending** |
| 6. UART flash | Waveshare FT232, manual CEN reset, CRC-checked write | **Pending** |
| 7. Device verification | RGBW, star laser, motor, button, stable Wi-Fi and power cycle | **Pending** |
| 8. Documentation | Record only measured and confirmed adjustments here | **After each validated milestone** |

**Decision:** no change to the source YAML, functionality, GPIO mapping or fixed LibreTiny candidate unless a concrete failure in the source/build proves the need. Never replace missing secrets with fake network credentials. The previous ESPHome-2026 build is not a flash candidate.

## 1. Confirm the source and install ESPHome 2024.4.1 on Debian

The one active build source is [`galaxy-evolve-2024-v0.1.yaml`](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml). Its Git blob is **`e099818947b7a7e8f1ae070ffffeae62e026af25`**, identical to the research repository. This is the complete configuration published by **Dawk323** on 27 April 2024 in the [Elektroda Evolve thread](https://www.elektroda.com/rtvforum/topic3984240.html), with user secrets externalized and the LibreTiny source fixed to candidate commit `d1386a8e9dcdeed4c50dd0628462b14c9295d304`. That commit is a reconstruction choice, **not** a proven exact historical dependency.

Included functions: RGBW GPIO6/26/24/9, star laser GPIO8, motor GPIO7 with 15% minimum power, button GPIO14, status indicator GPIO0, and `Random` / `Random Slow` effects. The source's two `relative_brightness: 5%` branches remain unchanged.

Run on Debian:

```bash
cd ~/projekte/bliss-evolve-android

git pull --ff-only

python3.11 --version

# Create a Python environment separate from the existing ESPHome 2026 install.
python3.11 -m venv ~/esphome-2024-env

# Install the pinned ESPHome version.
~/esphome-2024-env/bin/python -m pip install 'esphome==2024.4.1'

# Confirm the exact installed version.
~/esphome-2024-env/bin/esphome version
```

**Expected version output:** `Version: 2024.4.1`. A compatible local Python 3.11 installation is required for these commands. Stop and inspect any Python, package installation or version error rather than silently switching versions. The existing `~/esphome-env` remains untouched; it contains the `ltchiptool` used for the previously successful UART write.

## 2. Check and protect the real local secrets

The YAML already references the five keys below with `!secret`. Check whether the local file exists **without printing its contents**:

```bash
cd ~/projekte/bliss-evolve-android

test -s firmware/esphome/secrets.yaml \
  && echo "SECRETS_PRESENT" \
  || echo "SECRETS_MISSING"

git check-ignore -v firmware/esphome/secrets.yaml
```

If absent, create it locally:

```bash
nano firmware/esphome/secrets.yaml
```

Required structure (examples only; replace **all** placeholders with real values before compiling a firmware intended for flashing):

```yaml
wifi_ssid: "YOUR_REAL_WIFI_SSID"
wifi_password: "YOUR_REAL_WIFI_PASSWORD"
fallback_ap_password: "YOUR_OWN_AP_PASSWORD"
evolve_2024_api_key: "YOUR_BASE64_32_BYTE_API_KEY"
evolve_2024_ota_password: "YOUR_OWN_OTA_PASSWORD"
```

A new valid 32-byte ESPHome API encryption key can be generated locally:

```bash
python3 -c 'import secrets,base64; print(base64.b64encode(secrets.token_bytes(32)).decode())'
```

Use that output as `evolve_2024_api_key` if creating a new key; do not publish it. The fallback AP is named `Galaxy-Evolve` in the YAML and is not the home Wi-Fi SSID. Protect the file:

```bash
chmod 600 firmware/esphome/secrets.yaml
```

**Never commit this file, paste secrets into chat, or share unredacted configuration/build logs.** The compiled firmware may also embed credentials.

## 3. Validate and compile the original YAML

Only after the secrets are present, run the following **unchanged build sequence** from the old repository. `set -euo pipefail` stops on the first failed command; `umask 077` ensures newly created logs are private. The commands do **not** flash or otherwise write to the projector.

```bash
cd ~/projekte/bliss-evolve-android

(
  set -euo pipefail
  umask 077

  LOGDIR="$HOME/bliss-evolve-local/esphome-2024-build"
  mkdir -p "$LOGDIR"

  ESPHOME="$HOME/esphome-2024-env/bin/esphome"
  YAML="firmware/esphome/galaxy-evolve-2024-v0.1.yaml"

  test -s firmware/esphome/secrets.yaml

  "$ESPHOME" config "$YAML" \
    > "$LOGDIR/config.log" 2>&1

  echo "CONFIG_OK"

  "$ESPHOME" compile "$YAML" \
    > "$LOGDIR/compile.log" 2>&1

  echo "COMPILE_OK"

  echo "=== UF2 files found ==="

  find firmware/esphome \
    -type f -name '*.uf2' \
    -printf '%p | %s bytes\n'
)
```

Logs stay locally under `~/bliss-evolve-local/esphome-2024-build/`. A build may require internet access to fetch historical PlatformIO/LibreTiny components.

Expected milestones are `CONFIG_OK`, `COMPILE_OK` and the actual path(s) of newly produced UF2 files. **These are expectations, not results.** If either step fails, inspect the precise error locally; do not mass-rewrite the YAML, update framework versions or reduce hardware features.

Record the installed ESPHome version, any relevant PlatformIO/SDK/toolchain versions, compile result, actual image path, image size and SHA-256 before the next milestone.

## 4. Inspect the actual image before authorizing a flash

For the **newly compiled ESPHome 2024 UF2**, verify the UF2 structure, BK7231N/CBU target, physical flash ranges, bootloader protection, size, and SHA-256. A successful compile is not proof of a safe image or a functioning projector.

**Do not reuse the earlier ESPHome-2026 `firmware.uf2`.** The only device write transport proven to communicate with this BK7231N is FT232/UART and `ltchiptool flash write -c` with manual CEN-to-GND reset as described in [wiring.md](wiring.md). The exact UF2 path must come from the *new* compile. Verify that the installed `ltchiptool` enables 4 KiB-sector CRC checks and selective retries; no automatic complete readback/reflash is part of the standard procedure.

Firmware B uses the **UF2 mapping embedded in the compiled image**. It is distinct from [Recovery A](recovery.md), which restores the **complete 2 MiB foreign raw BIN** with explicit file/flash offsets. Never interchange those commands or image types.

**Flash only after the new UF2 passes QA and the user explicitly approves that specific image.** Then verify stable startup, home WLAN, RGBW, laser, motor, button and a power cycle.

## 5. Report progress and update this canonical guide

For the current local attempt, report: `esphome version`, whether `CONFIG_OK` and `COMPILE_OK` appeared, and UF2 path/size. For errors, share **only the relevant redacted error lines**, not complete logs that may contain keys.

Once verified, record the actual build environment, corrections (if necessary), image hash and hardware results **here in the new repository**. The old `bliss-evolve-android` repo remains the research/source archive.

## Change log

- **v1.2 (15 Nov 2026):** English working build procedure adopted from the currently agreed local instructions; source, secrets, isolated environment, exact error-stopping build commands, log handling, image QA, UART flash gate and post-flash checks captured. **No successful build or flash claimed.**
