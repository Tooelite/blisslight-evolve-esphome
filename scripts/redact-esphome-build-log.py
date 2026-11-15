#!/usr/bin/env python3
"""Create a redacted review candidate from an unredacted private ESPHome build log.

Fails closed if the local five-key secrets.yaml cannot be parsed. This is NOT
a guarantee that every possible credential from tools or the environment was
removed. The owner must inspect the review log before sharing.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import sys
from urllib.parse import quote

EXPECTED = (
    "wifi_ssid",
    "wifi_password",
    "fallback_ap_password",
    "evolve_2024_api_key",
    "evolve_2024_ota_password",
)


def fallback_parse(text: str) -> dict[str, str]:
    """Accept only simple one-line YAML string scalars, without substitutions."""
    result: dict[str, str] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*?)\s*", stripped)
        if not match:
            raise ValueError("Unsupported secrets.yaml syntax; cannot safely redact")
        key, value = match.groups()
        if key in result:
            raise ValueError(f"Duplicate secret key: {key}")
        if value.startswith('"'):
            try:
                parsed = json.loads(value)
            except (ValueError, TypeError):
                raise ValueError(f"Unsupported double-quoted secret syntax: {key}")
        elif value.startswith("'") and value.endswith("'"):
            parsed = value[1:-1].replace("''", "'")
        elif value.startswith(("|", ">", "!", "&", "*", "{", "[")):
            raise ValueError(f"Unsupported secret YAML scalar: {key}")
        else:
            parsed = value.split(" #", 1)[0].strip()
        if not isinstance(parsed, str):
            raise ValueError(f"Secret value is not text: {key}")
        result[key] = parsed
    return result


def read_secrets(path: Path) -> dict[str, str]:
    content = path.read_text(encoding="utf-8")
    try:
        import yaml  # available after successful ESPHome install
    except ImportError:
        data = fallback_parse(content)
    else:
        data = yaml.safe_load(content)
    if not isinstance(data, dict):
        raise ValueError("Secrets file is not a key/value mapping")
    missing = sorted(set(EXPECTED) - set(data))
    if missing:
        raise ValueError("Cannot redact: missing secret names: " + ", ".join(missing))
    values: dict[str, str] = {}
    for key in EXPECTED:
        value = data[key]
        if not isinstance(value, str) or len(value) < 3 or '\n' in value or '\r' in value:
            raise ValueError(f"Secret {key} must be a string of at least 3 characters for log redaction")
        values[key] = value
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--secrets", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        raise ValueError("Input and output must be separate files")
    values = read_secrets(args.secrets)
    substitutions: dict[str, str] = {}
    for key, value in values.items():
        marker = f"[REDACTED:{key}]"
        for variant in (value, json.dumps(value)[1:-1], quote(value, safe=""), shlex.quote(value)):
            if variant and variant != "''":
                substitutions[variant] = marker
    # Match longer strings first so partial overlap cannot expose a shorter token.
    substitutions_sorted = sorted(substitutions.items(), key=lambda pair: len(pair[0]), reverse=True)
    replacements = 0
    fd = os.open(args.output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with args.input.open("r", encoding="utf-8", errors="replace") as src, \
                os.fdopen(fd, "w", encoding="utf-8") as dst:
            dst.write("# REDACTED REVIEW COPY — inspect manually before sharing; not proof all secrets are gone.\n")
            for line in src:
                for secret, marker in substitutions_sorted:
                    if secret in line:
                        replacements += line.count(secret)
                        line = line.replace(secret, marker)
                dst.write(line)
    except Exception:
        args.output.unlink(missing_ok=True)
        raise
    print(f"REVIEW_REDACTION_REPLACEMENTS={replacements}")
    print("REVIEW_STATUS=created; review manually before sharing")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"REDACTION_FAILED: {exc}", file=sys.stderr)
        raise SystemExit(2)
