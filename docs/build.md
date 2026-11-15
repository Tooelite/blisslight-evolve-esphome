# ESPHome 2024.4.1 – full-function Evolve build

**Status (15.11.2026): source configuration present; local secrets, config validation, compilation and generated UF2 not yet verified.** This path is independent of the full original-BIN recovery. Both share the FT232/UART hardware procedure in [wiring.md](wiring.md).

## Source and versions

- Single firmware YAML: [galaxy-evolve-2024-v0.1.yaml](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml). Exact, unchanged Git blob from the original research repo: \`e099818947b7a7e8f1ae070ffffeae62e026af25\`.
- ESPHome **2024.4.1** in its own Python environment, not the existing ESPHome 2026 environment.
- The YAML pins LibreTiny commit \`d1386a8e9dcdeed4c50dd0628462b14c9295d304\` as a plausible historical reconstruction, **not a verified community build ID**.
- No firmware feature reductions or migrations. Functions: RGBW GPIO6/26/24/9, star laser GPIO8, motor GPIO7 minimum 15%, button GPIO14, status GPIO0 and two random color effects. The source's +5%/+5% hold-dimming behavior has intentionally not been altered.

## Local secrets, not in Git

Create \`firmware/esphome/secrets.yaml\` **on the build computer**, with real values for the intended projector network (never post values or include the file in Git):

\`\`\`yaml
wifi_ssid: "YOUR_REAL_WIFI_SSID"
wifi_password: "YOUR_REAL_WIFI_PASSWORD"
fallback_ap_password: "YOUR_OWN_AP_PASSWORD"
evolve_2024_api_key: "YOUR_BASE64_32_BYTE_API_KEY"
evolve_2024_ota_password: "YOUR_OWN_OTA_PASSWORD"
\`\`\`

The API key must decode from Base64 to exactly 32 bytes. The existing YAML already contains all matching \`!secret\` references; **do not hard-code credentials into it**. The fallback AP SSID is \`Galaxy-Evolve\`, independent from the home WLAN. The API/OTA keys and passwords become part of the built firmware: protect compiled binaries too.

## Debian – isolated build

In the root directory of **this repository**, with a locally available compatible \`python3.11\`:

\`\`\`bash
python3.11 -m venv ~/esphome-2024-env
~/esphome-2024-env/bin/python -m pip install 'esphome==2024.4.1'
~/esphome-2024-env/bin/esphome version

~/esphome-2024-env/bin/esphome config firmware/esphome/galaxy-evolve-2024-v0.1.yaml
~/esphome-2024-env/bin/esphome compile firmware/esphome/galaxy-evolve-2024-v0.1.yaml
\`\`\`

**Acceptance:** exact ESPHome version; successful \`config\` and \`compile\`, recorded tool/SDK versions, determined actual output paths and firmware size. If validation or compile fails, diagnose the specific failure; **do not silently change the YAML or update ESPHome/LibreTiny**. The compile commands above have **not yet been run successfully**. CLI configuration output may reveal secrets – review locally and redact before sharing.

## Image inspection and UART

Only after compilation: verify BK7231N/CBU target, UF2 metadata, flash ranges/bootloader preservation and firmware integrity; record the generated UF2's own hash. Do not reuse the old ESPHome-2026 UF2. A generated **ESPHome UF2** is flashed using \`ltchiptool flash write -c\` with auto-detected UF2 mapping; it is **not** the full raw-BIN restore. See [wiring.md](wiring.md) for FT232, CEN reset and the verified transport. **Never flash without a separate explicit decision.**
