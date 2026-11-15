#!/usr/bin/env bash
# Read-only QA for the build logger and redactor; never builds or flashes firmware.
set -Eeuo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
bash -n "$ROOT/build-esphome-2024.sh"
echo "PASS: builder Bash syntax"

PYTHON=""
for candidate in python3 python3.13 python3.12 python3.11 python3.10 python3.9; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$(command -v "$candidate")"
    break
  fi
done
[[ -n "$PYTHON" ]] || { echo "ERROR: no Python interpreter" >&2; exit 1; }
"$PYTHON" -m py_compile "$ROOT/redact-esphome-build-log.py"
echo "PASS: redactor Python syntax"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat >"$TMP/secrets.yaml" <<'SECRETS'
wifi_ssid: "SampleNetwork123"
wifi_password: "WiFi-test-password-123"
fallback_ap_password: "Fallback-test-password-123"
evolve_2024_api_key: "TEST-api-base64-key-123"
evolve_2024_ota_password: "OTA-test-password-123"
SECRETS
cat >"$TMP/raw.log" <<'LOG'
CONFIG_RUNNING
wifi_ssid: SampleNetwork123
wifi_password: WiFi-test-password-123
fallback_ap_password: Fallback-test-password-123
evolve_2024_api_key: TEST-api-base64-key-123
evolve_2024_ota_password: OTA-test-password-123
COMPILER: done
LOG

"$PYTHON" "$ROOT/redact-esphome-build-log.py" \
  --input "$TMP/raw.log" --secrets "$TMP/secrets.yaml" \
  --output "$TMP/review.log"
for token in SampleNetwork123 WiFi-test-password-123 Fallback-test-password-123 \
             TEST-api-base64-key-123 OTA-test-password-123; do
  if grep -Fq "$token" "$TMP/review.log"; then
    echo "ERROR: secret appeared in review log" >&2
    exit 1
  fi
done
grep -Fq 'COMPILER: done' "$TMP/review.log"
grep -Fq '[REDACTED:wifi_password]' "$TMP/review.log"
[[ "$(stat -c %a "$TMP/review.log")" == "600" ]] || {
  echo "ERROR: redacted review log permissions not 600" >&2
  exit 1
}
echo "PASS: five demo secrets redacted, non-secret output retained, file private"

# Incomplete secrets must fail closed, without producing a review file.
printf 'wifi_ssid: "Demo"\n' >"$TMP/bad-secrets.yaml"
if "$PYTHON" "$ROOT/redact-esphome-build-log.py" \
    --input "$TMP/raw.log" --secrets "$TMP/bad-secrets.yaml" \
    --output "$TMP/should-not-exist.log" >/dev/null 2>&1; then
  echo "ERROR: redactor accepted incomplete secrets" >&2
  exit 1
fi
[[ ! -e "$TMP/should-not-exist.log" ]]
echo "PASS: incomplete secrets fail closed"

# With pipefail enabled, logging cannot hide a failed command.
if (set -o pipefail; false 2>&1 | tee "$TMP/pipeline.log" >/dev/null); then
  echo "ERROR: tee concealed a failing build step" >&2
  exit 1
fi
echo "PASS: pipefail detects upstream error"

# Exercise the real confirmation helper via a pseudo-terminal: non-interactive
# execution, wrong answers and blank input must all abort. Only exact yes passes.
"$PYTHON" - "$ROOT/confirm-esphome-secrets.sh" <<'PYTEST'
import os
import subprocess
import sys

script = sys.argv[1]
base = ["bash", script, "/tmp/demo-bliss-workspace"]
required = (
    "firmware/esphome/secrets.yaml",
    "firmware/esphome/galaxy-evolve-2024-v0.1.yaml",
    "wifi_ssid", "wifi_password", "fallback_ap_password",
    "evolve_2024_api_key", "evolve_2024_ota_password",
)

def execute_in_pty(reply):
    master, slave = os.openpty()
    try:
        proc = subprocess.Popen(
            base, stdin=slave, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        os.close(slave)
        slave = -1
        os.write(master, (reply + "\n").encode("utf-8"))
        output, _ = proc.communicate(timeout=10)
        return proc.returncode, output.decode("utf-8", errors="replace")
    finally:
        os.close(master)
        if slave >= 0:
            os.close(slave)

noninteractive = subprocess.run(
    base, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT, text=True, check=False, timeout=10,
)
assert noninteractive.returncode != 0, "noninteractive confirmation was accepted"
assert "SECRETS_CONFIRMATION_ABORTED" in noninteractive.stdout
print("PASS: confirmation fails closed without a terminal")

for reply in ("no", "YES", "", "yes "):
    code, output = execute_in_pty(reply)
    assert code != 0, f"invalid answer {reply!r} was accepted"
    assert "SECRETS_CONFIRMATION_ABORTED" in output, output
    assert "SECRETS_CONFIRMATION=yes" not in output
print("PASS: invalid or empty confirmation aborts")

code, output = execute_in_pty("yes")
assert code == 0, f"exact yes was incorrectly refused: {output}"
assert "SECRETS_CONFIRMATION=yes" in output
for key in required:
    assert key in output, f"missing secret path/key prompt: {key}"
print("PASS: only exact yes passes and all five secret keys and paths are displayed")
PYTEST

echo "LOGGING_QA_OK"
