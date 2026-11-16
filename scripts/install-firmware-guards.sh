#!/usr/bin/env bash
# Opt-in local Git hooks. Does not change tracked firmware or remote settings.
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel)"
[[ "$(pwd -P)" == "$ROOT" ]] || { echo "Run from repository root" >&2; exit 1; }
HOOKS="$(git rev-parse --git-path hooks)"
mkdir -p -- "$HOOKS"
for hook in pre-commit pre-push; do
  target="$HOOKS/$hook"
  [[ ! -e "$target" ]] || { echo "Existing hook preserved: $target" >&2; exit 1; }
done
for hook in pre-commit pre-push; do
  target="$HOOKS/$hook"
  if [[ "$hook" == pre-push ]]; then mode="--pre-push"; else mode=""; fi
  printf '#!/usr/bin/env bash\nset -Eeuo pipefail\nexec python3 "%s" %s\n' "$ROOT/scripts/guard-firmware-secrets.py" "$mode" >"$target"
  chmod 700 "$target"
done
echo "Installed local pre-commit and pre-push secret guards"
