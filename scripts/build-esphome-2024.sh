#!/usr/bin/env bash
# Build-only: does not access /dev/ttyUSB*, CEN, or write firmware to hardware.
set -Eeuo pipefail
umask 077

WORKSPACE="${1:-$HOME/projekte/bliss-evolve-android}"
VENV="${ESPHOME_2024_VENV:-$HOME/esphome-2024-env}"
LOGDIR="$HOME/bliss-evolve-local/esphome-2024-build"
YAML_REL="firmware/esphome/galaxy-evolve-2024-v0.1.yaml"
EXPECTED_YAML_BLOB="e099818947b7a7e8f1ae070ffffeae62e026af25"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "$WORKSPACE/.git" ]] || die "Not a Git checkout: $WORKSPACE"
[[ -f "$WORKSPACE/$YAML_REL" ]] || die "Missing source YAML: $WORKSPACE/$YAML_REL"
command -v git >/dev/null 2>&1 || die "Git not installed"
actual_blob="$(git -C "$WORKSPACE" hash-object "$YAML_REL")"
[[ "$actual_blob" == "$EXPECTED_YAML_BLOB" ]] || die "Unexpected YAML changes ($actual_blob). Review source before updating the build procedure."

# PyPI metadata for esphome==2024.4.1 declares Python >=3.9.
# Prefer the 2024-era runtimes; use 3.13 only if no older compatible interpreter exists.
# The older dependency stack may still fail on 3.13 despite satisfying metadata.
is_candidate() {
  "$1" -c 'import sys; v=sys.version_info; raise SystemExit(0 if v.major == 3 and 9 <= v.minor <= 13 else 1)' >/dev/null 2>&1
}

if [[ -d "$VENV" ]]; then
  [[ -x "$VENV/bin/python" ]] || die "Existing environment is incomplete: $VENV (not overwritten)"
  is_candidate "$VENV/bin/python" || die "Existing environment uses an unchecked Python version: $VENV"
  printf 'USING_EXISTING_ENV=%s\n' "$VENV"
else
  PYTHON=""
  for cmd in python3.12 python3.11 python3.10 python3.9 python3.13 python3; do
    if command -v "$cmd" >/dev/null 2>&1 && is_candidate "$cmd"; then
      PYTHON="$(command -v "$cmd")"
      break
    fi
  done
  [[ -n "$PYTHON" ]] || die "No usable Python 3.9–3.13 interpreter found; no installation attempted"
  printf 'SELECTED_PYTHON=%s\n' "$PYTHON"
  "$PYTHON" --version
  "$PYTHON" -m venv "$VENV" || die "venv creation failed using $PYTHON (check venv/ensurepip, without modifying system Python)"
fi

VENV_PYTHON="$VENV/bin/python"
ESPHOME="$VENV/bin/esphome"
"$VENV_PYTHON" -m pip --version >/dev/null 2>&1 || die "No pip inside $VENV"

mkdir -p "$LOGDIR"
printf 'BUILD_LOG_DIR=%s\n' "$LOGDIR"
printf 'ENV_PYTHON='
"$VENV_PYTHON" --version

# Avoid repeated pip work if the desired version is already available.
if [[ ! -x "$ESPHOME" ]] || ! "$ESPHOME" version 2>/dev/null | grep -Fq 'Version: 2024.4.1'; then
  if ! "$VENV_PYTHON" -m pip install --disable-pip-version-check 'esphome==2024.4.1' >"$LOGDIR/pip-install.log" 2>&1; then
    die "PIP_INSTALL_FAILED: inspect $LOGDIR/pip-install.log; do not change ESPHome/Python versions blindly"
  fi
fi

VERSION="$("$ESPHOME" version 2>&1)" || die "Installed ESPHome cannot start"
printf '%s\n' "$VERSION"
printf '%s\n' "$VERSION" | grep -Fq 'Version: 2024.4.1' || die "Wrong ESPHome version; expected 2024.4.1"

SECRETS="$WORKSPACE/firmware/esphome/secrets.yaml"
[[ -s "$SECRETS" ]] || die "SECRETS_MISSING: create $SECRETS with real credentials (never share the file)"
if ! git -C "$WORKSPACE" check-ignore -q "$SECRETS"; then
  die "Secrets file is NOT Git-ignored: $SECRETS"
fi
chmod 600 "$SECRETS"

YAML="$WORKSPACE/$YAML_REL"
if ! "$ESPHOME" config "$YAML" >"$LOGDIR/config.log" 2>&1; then
  die "CONFIG_FAILED: inspect $LOGDIR/config.log locally; redact secrets before sharing excerpts"
fi
printf 'CONFIG_OK\n'

if ! "$ESPHOME" compile "$YAML" >"$LOGDIR/compile.log" 2>&1; then
  die "COMPILE_FAILED: inspect $LOGDIR/compile.log locally; redact secrets before sharing excerpts"
fi
printf 'COMPILE_OK\n'

# Restrict discovery to the expected 2024 project name; never select an older ESPHome-2026 image.
UF2_DIR="$WORKSPACE/firmware/esphome/.esphome/build/galaxy-lamp"
if [[ ! -d "$UF2_DIR" ]]; then
  die "UF2_DIR_MISSING: review $LOGDIR/compile.log for the actual build path"
fi
find "$UF2_DIR" -type f -name '*.uf2' -printf '%p | %s bytes\n' | tee "$LOGDIR/uf2-files.txt"
[[ -s "$LOGDIR/uf2-files.txt" ]] || die "UF2_NOT_FOUND: compile succeeded but image location still needs verification"

printf 'IMAGE_QA_PENDING: inspect UF2 target, flash ranges, hash and build logs before any flash\n'
