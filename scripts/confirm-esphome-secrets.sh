#!/usr/bin/env bash
# Two-stage confirmation. Display secret values only on the local terminal, never via tee.
set -Eeuo pipefail

if (( $# != 1 )); then
  printf 'ERROR: Expected exactly one workspace path\n' >&2
  exit 2
fi

WORKSPACE="$1"
SECRETS="$WORKSPACE/firmware/esphome/secrets.yaml"
SOURCE_YAML="$WORKSPACE/firmware/esphome/galaxy-evolve-2024-v0.1.yaml"

printf '\n===== MANDATORY SECRET CONFIGURATION CONFIRMATION =====\n'
printf 'Firmware source (contains !secret references):\n  %s\n' "$SOURCE_YAML"
printf 'Required local secret values must be entered in:\n  %s\n' "$SECRETS"
printf 'Required keys (use actual values, not example placeholders):\n'
printf '  wifi_ssid                 - home Wi-Fi SSID\n'
printf '  wifi_password             - home Wi-Fi password\n'
printf '  fallback_ap_password      - fallback access-point password\n'
printf '  evolve_2024_api_key       - Base64 key for 32 raw encryption bytes\n'
printf '  evolve_2024_ota_password  - ESPHome OTA password\n'
printf 'After the first yes, the file contents will appear on your terminal, not in the build log.\n'

if [[ ! -t 0 ]]; then
  printf 'SECRETS_CONFIRMATION_ABORTED: no interactive terminal; run the build in a terminal and enter exactly yes.\n' >&2
  exit 3
fi

printf '\nHave you personally entered all FIVE real values at the path above? Type exactly yes to continue: '
confirmation=""
if ! IFS= read -r confirmation; then
  printf '\nSECRETS_CONFIRMATION_ABORTED: input unavailable or interrupted.\n' >&2
  exit 3
fi

if [[ "$confirmation" != "yes" ]]; then
  printf 'SECRETS_CONFIRMATION_ABORTED: only the exact response yes allows the build to proceed.\n' >&2
  exit 3
fi

# The build process is piped through tee. Never send the actual secrets to
# stdout/stderr: print them directly to the controlling terminal instead.
# If no controlling terminal exists, fail closed rather than expose secrets.
if [[ ! -r "$SECRETS" || ! -c /dev/tty ]]; then
  printf 'SECRETS_CONFIRMATION_ABORTED: local secrets or controlling terminal unavailable.\n' >&2
  exit 3
fi

if ! {
  printf '\n===== LOCAL SECRETS (TERMINAL ONLY — NOT IN BUILD LOG) =====\n'
  cat -- "$SECRETS"
  printf '\nAre these settings correct? Type exactly yes to continue: '
} >/dev/tty; then
  printf 'SECRETS_CONFIRMATION_ABORTED: cannot display secrets on the local terminal.\n' >&2
  exit 3
fi

settings_confirmed=""
if ! IFS= read -r settings_confirmed </dev/tty; then
  printf 'SECRETS_CONFIRMATION_ABORTED: settings verification interrupted.\n' >&2
  exit 3
fi

if [[ "$settings_confirmed" != "yes" ]]; then
  printf 'SECRETS_CONFIRMATION_ABORTED: settings were not confirmed.\n' >&2
  exit 3
fi

printf 'SECRETS_CONFIRMATION=yes\n'
