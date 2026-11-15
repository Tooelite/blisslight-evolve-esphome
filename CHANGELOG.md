# Changelog

## Unreleased

- Allow standalone builds from an ordinary directory; remove fixed YAML Git-hash verification and Git-dependent preflight checks.
- Initialize missing or empty local secrets from the tracked example; require confirmation and reject untouched placeholders.
- Clear previous build-generated logs before each run while preserving unrelated files and preventing concurrent builds.
- Provide an English technical reference for ESPHome, full raw recovery and FT232 wiring.
- Build the included ESPHome configuration from the same repository, using an isolated Python environment.
- Require interactive confirmation of local secrets before build actions.
- Capture live compiler output, private full logs and a redacted review copy.
- Keep the original community firmware archive with size and checksum verification.

## Initial source import

- Preserve the community Evolve YAML and the original 2 MiB BK7231N flash reference image.
