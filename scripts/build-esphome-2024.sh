#!/usr/bin/env bash
# Build-only: does not access /dev/ttyUSB*, CEN or write projector firmware.
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
WORKSPACE="${1:-$PROJECT_ROOT}"
VENV="${ESPHOME_2024_VENV:-$WORKSPACE/.venv}"
LOGDIR="${ESPHOME_2024_LOGDIR:-$WORKSPACE/.build-logs}"
YAML="$WORKSPACE/firmware/esphome/galaxy-evolve-2024-v0.1.yaml"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
stage() { printf '\n===== %s =====\n' "$*"; }

# Each invocation gets fresh protected files. tee shows worker stdout/stderr
# on screen AND saves them. PIPESTATUS ensures a failed build remains failed.
if [[ "${ESPHOME_BUILD_LOG_WORKER:-0}" != "1" ]]; then
  mkdir -p "$LOGDIR" || die "Cannot create log directory: $LOGDIR"
  command -v flock >/dev/null 2>&1 || die "flock is required to prevent concurrent build runs"
  exec 9>"$LOGDIR/.build.lock"
  flock -n 9 || die "Another build is already running; old logs were not removed"

  # Remove only artifacts from preceding builds, never source files, secrets,
  # the virtual environment or the actual compiled firmware.
  find "$LOGDIR" -maxdepth 1 -type f \( \
      -name 'build-*.full-private.log' -o \
      -name 'build-*.config-private.log' -o \
      -name 'build-*.compile-private.log' -o \
      -name 'build-*.pip-private.log' -o \
      -name 'build-*.review.log' -o \
      -name 'build-*.uf2-files.txt' \
    \) -delete || die "Failed to remove logs from the previous build"
  printf 'PREVIOUS_BUILD_LOGS_CLEARED=%s\n' "$LOGDIR"

  RUN_ID="$(date -u '+%Y%m%dT%H%M%SZ')-$$"
  export ESPHOME_BUILD_LOG_WORKER=1
  export ESPHOME_BUILD_RUN_ID="$RUN_ID"
  export ESPHOME_BUILD_CONFIG_LOG="$LOGDIR/build-$RUN_ID.config-private.log"
  FULL_LOG="$LOGDIR/build-$RUN_ID.full-private.log"
  REVIEW_LOG="$LOGDIR/build-$RUN_ID.review.log"

  {
    printf 'BUILD_RUN_ID=%s\nLIVE_OUTPUT=enabled\n' "$RUN_ID"
    printf 'PRIVATE_FULL_LOG=%s\n' "$FULL_LOG"
    printf 'REVIEW_LOG_PLANNED=%s\n' "$REVIEW_LOG"
    printf 'CONFIG_OUTPUT=private_only (resolved config can contain credentials)\n'
  } | tee "$FULL_LOG"

  set +e
  bash "$0" "$@" 2>&1 | tee -a "$FULL_LOG"
  statuses=( "${PIPESTATUS[@]}" )
  set -e
  worker_status="${statuses[0]}"
  tee_status="${statuses[1]}"

  # Config prints resolved secrets: append its full, unfiltered output only
  # to the private transcript, never to the terminal.
  if [[ -f "$ESPHOME_BUILD_CONFIG_LOG" ]]; then
    {
      printf '\n===== ESPHOME CONFIG RAW OUTPUT (PRIVATE; APPENDED AFTER BUILD) =====\n'
      cat "$ESPHOME_BUILD_CONFIG_LOG"
    } >>"$FULL_LOG"
  fi
  printf '\nBUILD_EXIT_CODE=%s\nTEE_EXIT_CODE=%s\n' "$worker_status" "$tee_status" | tee -a "$FULL_LOG"

  # Try to produce a separately redacted review file. If secrets cannot be
  # interpreted reliably, fail closed and leave only the private transcript.
  REDACT_PYTHON=""
  if [[ -x "$VENV/bin/python" ]]; then
    REDACT_PYTHON="$VENV/bin/python"
  else
    for candidate in python3 python3.13 python3.12 python3.11 python3.10 python3.9; do
      if command -v "$candidate" >/dev/null 2>&1; then
        REDACT_PYTHON="$(command -v "$candidate")"
        break
      fi
    done
  fi
  if [[ -n "$REDACT_PYTHON" ]] && "$REDACT_PYTHON" "$SCRIPT_DIR/redact-esphome-build-log.py" \
      --input "$FULL_LOG" --secrets "$WORKSPACE/firmware/esphome/secrets.yaml" \
      --output "$REVIEW_LOG"; then
    printf 'REVIEW_LOG=%s\n' "$REVIEW_LOG"
    printf 'WARNING=Inspect review log for other sensitive values before sharing.\n'
  else
    printf 'REVIEW_LOG_NOT_CREATED=redaction failed; do not share the private log.\n' >&2
  fi
  printf 'PRIVATE_FULL_LOG=%s\n' "$FULL_LOG"
  if (( tee_status != 0 )); then
    printf 'ERROR: tee failed (code %s); build result cannot be accepted.\n' "$tee_status" >&2
    exit "$tee_status"
  fi
  exit "$worker_status"
fi

stage "Source preflight"
printf 'WORKSPACE=%s\nRUN_ID=%s\n' "$WORKSPACE" "$ESPHOME_BUILD_RUN_ID"
[[ -f "$YAML" && -s "$YAML" ]] || die "Missing or empty firmware YAML: $YAML"

stage "Prepare local secrets"
SECRETS="$WORKSPACE/firmware/esphome/secrets.yaml"
TEMPLATE="$WORKSPACE/firmware/esphome/secrets.example.yaml"
[[ -f "$TEMPLATE" && -s "$TEMPLATE" ]] || die "Missing tracked secrets template: $TEMPLATE"
[[ ! -L "$SECRETS" ]] || die "Refusing to replace a symlinked secrets file: $SECRETS"
if [[ ! -s "$SECRETS" ]] || ! grep -q '[^[:space:]]' "$SECRETS" 2>/dev/null; then
  [[ ! -e "$SECRETS" || -f "$SECRETS" ]] || die "Secrets path is not a regular file"
  install -m 600 -- "$TEMPLATE" "$SECRETS" || die "Cannot initialize secrets from template"
  printf 'SECRETS_TEMPLATE_COPIED=%s\n' "$SECRETS"
else
  printf 'SECRETS_FILE_PRESERVED=%s\n' "$SECRETS"
fi
chmod 600 "$SECRETS"

# Two confirmations before venv creation, dependency installation or
# compilation. Secret values are shown only on /dev/tty (not through tee).
bash "$SCRIPT_DIR/confirm-esphome-secrets.sh" "$WORKSPACE" || die "Build aborted at the secrets confirmation gate"

# A yes answer alone must never permit firmware with untouched placeholders.
for placeholder in REPLACE_WITH_WIFI_SSID REPLACE_WITH_WIFI_PASSWORD \
  REPLACE_WITH_FALLBACK_AP_PASSWORD REPLACE_WITH_BASE64_32_BYTE_API_KEY \
  REPLACE_WITH_OTA_PASSWORD; do
  if grep -Fq -- "$placeholder" "$SECRETS"; then
    die "SECRETS_INCOMPLETE: replace every template placeholder in $SECRETS"
  fi
done
[[ -s "$SECRETS" ]] || die "SECRETS_MISSING: $SECRETS"
printf 'SECRETS_CONFIRMED_AND_TEMPLATE_PLACEHOLDERS_CLEARED\n'

stage "Select installed Python"
is_candidate() {
  "$1" -c 'import sys; v=sys.version_info; raise SystemExit(0 if v.major == 3 and 9 <= v.minor <= 13 else 1)' >/dev/null 2>&1
}
if [[ -d "$VENV" ]]; then
  [[ -x "$VENV/bin/python" ]] || die "Incomplete existing venv (preserved): $VENV"
  is_candidate "$VENV/bin/python" || die "Existing venv has an unchecked Python version"
  printf 'USING_EXISTING_VENV=%s\n' "$VENV"
else
  PYTHON=""
  for candidate in python3.12 python3.11 python3.10 python3.9 python3.13 python3; do
    if command -v "$candidate" >/dev/null 2>&1 && is_candidate "$candidate"; then
      PYTHON="$(command -v "$candidate")"
      break
    fi
  done
  [[ -n "$PYTHON" ]] || die "No usable Python 3.9–3.13. No installation attempted."
  printf 'SELECTED_PYTHON=%s\n' "$PYTHON"
  "$PYTHON" --version
  "$PYTHON" -m venv "$VENV" || die "venv creation failed with $PYTHON; check ensurepip/venv"
fi

VENV_PYTHON="$VENV/bin/python"
ESPHOME="$VENV/bin/esphome"
"$VENV_PYTHON" --version
"$VENV_PYTHON" -m pip --version || die "pip missing from venv"

stage "Pin and verify ESPHome 2024.4.1"
PIP_LOG="$LOGDIR/build-$ESPHOME_BUILD_RUN_ID.pip-private.log"
if [[ ! -x "$ESPHOME" ]] || ! "$ESPHOME" version 2>/dev/null | grep -Fq 'Version: 2024.4.1'; then
  if ! "$VENV_PYTHON" -m pip install --disable-pip-version-check 'esphome==2024.4.1' 2>&1 | tee "$PIP_LOG"; then
    die "PIP_INSTALL_FAILED: inspect $PIP_LOG"
  fi
else
  printf 'PIP_INSTALL_SKIPPED=installed ESPHome already matches\n'
fi
VERSION="$("$ESPHOME" version 2>&1)" || die "Installed ESPHome cannot start"
printf '%s\n' "$VERSION"
printf '%s\n' "$VERSION" | grep -Fq 'Version: 2024.4.1' || die "Wrong ESPHome version"

stage "Validate configuration (private output only)"
printf 'CONFIG_PRIVATE_LOG=%s\nCONFIG_RUNNING=output hidden to protect credentials\n' "$ESPHOME_BUILD_CONFIG_LOG"
if ! "$ESPHOME" config "$YAML" >"$ESPHOME_BUILD_CONFIG_LOG" 2>&1; then
  die "CONFIG_FAILED: inspect $ESPHOME_BUILD_CONFIG_LOG privately"
fi
printf 'CONFIG_OK\n'

stage "Compile firmware (live progress + captured)"
COMPILE_LOG="$LOGDIR/build-$ESPHOME_BUILD_RUN_ID.compile-private.log"
if ! "$ESPHOME" compile "$YAML" 2>&1 | tee "$COMPILE_LOG"; then
  die "COMPILE_FAILED: inspect $COMPILE_LOG"
fi
printf 'COMPILE_OK\n'

stage "Collect UF2 candidates (no flash)"
UF2_DIR="$WORKSPACE/firmware/esphome/.esphome/build/galaxy-lamp"
[[ -d "$UF2_DIR" ]] || die "UF2_DIR_MISSING: inspect compile output for path"
UF2_LOG="$LOGDIR/build-$ESPHOME_BUILD_RUN_ID.uf2-files.txt"
find "$UF2_DIR" -type f -name '*.uf2' -printf '%p | %s bytes\n' | tee "$UF2_LOG"
[[ -s "$UF2_LOG" ]] || die "UF2_NOT_FOUND: inspect compile output"
printf 'UF2_SHA256_CANDIDATES\n'
find "$UF2_DIR" -type f -name '*.uf2' -exec sha256sum {} +
printf 'IMAGE_QA_PENDING=UF2 structure/target/flash ranges not yet verified\n'
printf 'NO_FLASH_PERFORMED\n'
