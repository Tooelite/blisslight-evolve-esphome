#!/usr/bin/env bash
set -euo pipefail
# Intentionally non-writing: the full-dump layout, protected regions and adapter wiring
# require independent verification before an executable flash command is approved.
image="${1:-firmware/recovery/recovery-image.bin}"
python3 scripts/check-image.py "$image"
cat <<'EOF'
STOP: image checksum passed, but the full 2 MiB foreign-device dump is NOT cleared for writing.
Required gates: confirm UART wiring and voltage; inspect bootloader/config/identity partitions;
confirm current ltchiptool version, supported input format and flash offsets;
retain a safe backup of accessible device regions; obtain explicit user authorization.
The previously proven write involved a different ESPHome image, not this recovery dump.
EOF
exit 3
