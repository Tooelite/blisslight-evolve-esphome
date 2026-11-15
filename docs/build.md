# Firmware B – build the complete Evolve image with ESPHome 2024.4.1

**Working procedure v1.4 – 15 November 2026.** This document records the exact build sequence agreed for the next local attempt on Debian. **No ESPHome 2024.4.1 configuration validation, compilation, UF2 verification, or 2024-image flash has succeeded yet.** Update the steps only when the actual local logs justify a correction.

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

## 1. Confirm the source and interpreter requirements

The one active build source is [`galaxy-evolve-2024-v0.1.yaml`](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml). Its Git blob is **`e099818947b7a7e8f1ae070ffffeae62e026af25`**, identical to the research repository. This is the complete configuration published by **Dawk323** on 27 April 2024 in the [Elektroda Evolve thread](https://www.elektroda.com/rtvforum/topic3984240.html), with user secrets externalized and the LibreTiny source fixed to candidate commit `d1386a8e9dcdeed4c50dd0628462b14c9295d304`. That commit is a reconstruction choice, **not** a proven exact historical dependency.

Included functions: RGBW GPIO6/26/24/9, star laser GPIO8, motor GPIO7 with 15% minimum power, button GPIO14, status indicator GPIO0, and `Random` / `Random Slow` effects. The source's two `relative_brightness: 5%` branches remain unchanged.

**Confirmed on the target Debian host:** `/usr/bin/python3` reports **Python 3.13.5**. The earlier command `python3.11` failed simply because that executable name does not exist there; this did not prove Python was absent.

PyPI release metadata for `esphome==2024.4.1` specifies **Python >=3.9**, without an upper bound. However, the April 2024 dependency stack is **not verified on Python 3.13**. We therefore auto-discover the available interpreter instead of assuming a specific `python3.X` executable. The build script prefers available Python 3.12/3.11/3.10/3.9 and falls back to Python 3.13 (or a suitable `python3` alias). It checks the version before creating a virtual environment, and reports a specific dependency error if installation fails. **No system Python installation or upgrade is performed.**

The build script lives in this canonical repository: [`scripts/build-esphome-2024.sh`](../scripts/build-esphome-2024.sh). It uses the historical firmware YAML in `~/projekte/bliss-evolve-android`, verifies the exact original Git blob, keeps `~/esphome-env` intact, and never flashes hardware. **Prepare real secrets (next section) before executing the build command in step 3.**

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

After the five real secrets are present, execute the following from Debian. **You do not need to guess the Python command name or install a particular Python minor version first.**

```bash
# Make sure the canonical build scripts are available locally.
git -C ~/projekte/blisslight-evolve-esphome pull --ff-only

# Read-only logging QA first: syntax, redaction with dummy secrets, pipefail.
bash ~/projekte/blisslight-evolve-esphome/scripts/test-build-logging.sh

# Run the unchanged 2024 YAML build in the historical repository.
bash ~/projekte/blisslight-evolve-esphome/scripts/build-esphome-2024.sh \
  ~/projekte/bliss-evolve-android
```

The command automatically:

1. Confirms the working repo and original firmware YAML Git blob.
2. Discovers an installed Python 3.9–3.13 executable (preferring period-appropriate versions), **prints the selected interpreter and version**, and creates or checks the independent `~/esphome-2024-env` virtual environment.
3. Installs **exactly ESPHome 2024.4.1**, or reuses it if already present and verified.
4. Checks the real local secrets, Git ignore rule and file permissions.
5. Runs `esphome config` and `esphome compile` with `set -Eeuo pipefail`, `umask 077`, protected logs, and **live terminal progress** through `tee`. The entire worker's stdout and stderr are recorded in one uniquely named private run transcript; a config-output appendix contains resolved configuration values that can include secrets.
6. Searches for UF2 files **only within the expected `galaxy-lamp` build directory**, avoiding accidental selection of the old 2026 UF2; prints size and SHA-256 of every candidate, but **does not approve or flash it**.

### Logging: live screen + complete local capture

Each invocation creates a new unique run ID, with files under `~/bliss-evolve-local/esphome-2024-build/`:

| File | Contents | Sharing rule |
| --- | --- | --- |
| `build-<run-id>.full-private.log` | Complete stdout/stderr from the build worker, plus the **unfiltered** `esphome config` output appended as a separate section; includes error codes | **Never upload directly** |
| `build-<run-id>.review.log` | Automatically redacted copy of the complete transcript, replacing the five configured secret values where recognized | **Inspect locally first**, then share for analysis |
| `build-<run-id>.config-private.log` | Original `esphome config` output (could display actual passwords and API keys) | **Keep private** |
| `build-<run-id>.pip-private.log`, `build-<run-id>.compile-private.log`, `build-<run-id>.uf2-files.txt` | Separate phase logs for focused troubleshooting | Treat as private until reviewed |

**On-screen progress:** Python selection, package installation, warnings, compiler output, failure messages, and UF2 discovery are displayed as they happen **and** recorded by `tee`. **Exception:** raw resolved `esphome config` output is withheld from the screen because it can reveal Wi-Fi/API passwords; the terminal shows `CONFIG_RUNNING` and then `CONFIG_OK` or `CONFIG_FAILED` instead. Its full output is nonetheless saved in the private transcript.

**Error correctness:** Bash `pipefail` and explicit `PIPESTATUS` handling preserve the failed command's exit code even if `tee` succeeded. The local `scripts/test-build-logging.sh` checks Bash/Python syntax, redaction using **dummy test secrets**, fail-closed behavior and upstream error propagation; it **does not compile or flash anything**. Run it before the build. Any `tee` failure invalidates the run. A new run never overwrites a previous run's log.

**Redaction limits:** `scripts/redact-esphome-build-log.py` attempts to remove the five YAML secret values in plain/quoted/URL-encoded form. Unknown credentials (e.g. private package-index tokens, serials, build flags) may remain. The script **refuses to create a review log** if the secrets are missing or cannot be parsed safely. **Inspect `build-<run-id>.review.log` for sensitive content before sharing it with ChatGPT.**

Expected milestones are `CONFIG_OK`, `COMPILE_OK`, and the real UF2 path/size/hash. **These are expectations, not reported results.** No script here performs image layout QA or flashes hardware. A successful compile only enables the next QA step.

Record the actual selected Python version, ESPHome/PlatformIO/SDK versions, completed image path, image size, and SHA-256 before the next milestone.

## 4. Inspect the actual image before authorizing a flash

For the **newly compiled ESPHome 2024 UF2**, verify the UF2 structure, BK7231N/CBU target, physical flash ranges, bootloader protection, size, and SHA-256. A successful compile is not proof of a safe image or a functioning projector.

**Do not reuse the earlier ESPHome-2026 `firmware.uf2`.** The only device write transport proven to communicate with this BK7231N is FT232/UART and `ltchiptool flash write -c` with manual CEN-to-GND reset as described in [wiring.md](wiring.md). The exact UF2 path must come from the *new* compile. Verify that the installed `ltchiptool` enables 4 KiB-sector CRC checks and selective retries; no automatic complete readback/reflash is part of the standard procedure.

Firmware B uses the **UF2 mapping embedded in the compiled image**. It is distinct from [Recovery A](recovery.md), which restores the **complete 2 MiB foreign raw BIN** with explicit file/flash offsets. Never interchange those commands or image types.

**Flash only after the new UF2 passes QA and the user explicitly approves that specific image.** Then verify stable startup, home WLAN, RGBW, laser, motor, button and a power cycle.

## 5. Report progress and update this canonical guide

For the current local attempt, provide the generated **`build-<run-id>.review.log`** after inspecting it for sensitive content. The script prints its full path as `REVIEW_LOG=...`. This review copy contains full stage detail after secret masking, including failure output when available. **Never upload `*.full-private.log`, `*.config-private.log`, or `secrets.yaml`.** If review-log creation fails, share only manually checked error excerpts instead.

Once verified, record the actual build environment, corrections (if necessary), image hash and hardware results **here in the new repository**. The old `bliss-evolve-android` repo remains the research/source archive.

## Change log

- **v1.2 (15 Nov 2026):** English working build procedure recorded from the agreed local instructions.
- **v1.3 (15 Nov 2026):** Replaced the unverified `python3.11` executable assumption with Python autodetection; recorded local Debian Python 3.13.5.
- **v1.4 (15 Nov 2026):** Added live `tee` progress, unique protected full-run transcripts, separate phase logs, automatic secret-redacted review copies, and error-code preservation. **No actual ESPHome 2024 build or flash claimed.**
