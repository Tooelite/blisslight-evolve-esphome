#!/usr/bin/env bash
set -euo pipefail
# Debian/Ubuntu: install prerequisites and isolate ltchiptool from system Python.
command -v python3 >/dev/null || { echo 'python3 missing' >&2; exit 1; }
command -v apt-get >/dev/null || { echo 'Debian/Ubuntu apt-get required' >&2; exit 1; }
echo 'Install prerequisites using: sudo apt-get update && sudo apt-get install -y python3-venv python3-pip usbutils'
if ! python3 -m venv .venv; then echo 'venv failed; install python3-venv first' >&2; exit 1; fi
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install ltchiptool
.venv/bin/python -m pip show ltchiptool
printf '\nRun .venv/bin/ltchiptool --help and .venv/bin/ltchiptool flash write --help before using any flash commands.\n'
