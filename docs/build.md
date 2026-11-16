# Build the current firmware

Source: [`galaxy-evolve-v0.3-dev.yaml`](../firmware/esphome/galaxy-evolve-v0.3-dev.yaml). Use official ESPHome commit **`602cbff184c105be128a01f8d61994407988a914`** (`2026.12.0-dev`), which selects LibreTiny 1.14.0 and Beken BDK 3.0.78 for CBU/BK7231N. Do not substitute an older installed ESPHome release or add a manual framework pin.

## Install the pinned official CLI

Requirements: Linux, Git, Python **3.12–3.15** with `venv`/`pip`, Internet access and enough space for the toolchain. From the repository root:

```bash
python3 --version
git --version
python3 -m venv .venv-v0.3-dev
.venv-v0.3-dev/bin/python -m pip install 'git+https://github.com/esphome/esphome.git@602cbff184c105be128a01f8d61994407988a914'
.venv-v0.3-dev/bin/esphome version
```

The hardware-confirmed build used Python 3.14.7; the supported interpreter range above comes from the pinned package metadata. The version should be `2026.12.0-dev`. The fixed Git commit identifies the exact source; the version string alone does not. This uses ESPHome's own build process and leaves any desktop installation separate.

Verify the installed source commit (expected: `602cbff184c105be128a01f8d61994407988a914`):

```bash
.venv-v0.3-dev/bin/python -c 'import importlib.metadata as m, json; print(json.loads(m.distribution("esphome").read_text("direct_url.json"))["vcs_info"]["commit_id"])'
```

## Create the private configuration

```bash
umask 077
cp -n -- firmware/esphome/galaxy-evolve-v0.3-dev.yaml firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
chmod 600 firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

The copy command preserves an existing local file. If one already exists, check its non-secret settings against the current template without overwriting its credentials.

Edit **only the local copy** and replace all five `INSERT_*` values:

| Field | Required value |
| --- | --- |
| `wifi.ssid` | Home Wi-Fi name |
| `wifi.password` | Home Wi-Fi password |
| `wifi.ap.password` | Fallback AP password |
| `api.encryption.key` | Base64-encoded 32-byte API encryption key |
| `ota[0].password` | ESPHome OTA password |

Keep `wifi.hidden: true`, the logger settings and the hardware assignments as supplied. No MAC override is required. `hidden: true` controls the device's direct SSID join; leave the router SSID visible if it is already visible.

Verify that the private file is ignored and untracked:

```bash
git check-ignore firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
git ls-files -- firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

The first command must report the path; the second must produce no output because the file is not tracked. Do not build or flash with placeholder credentials. Do not print, commit or share the resolved configuration.

## Validate and compile

```bash
.venv-v0.3-dev/bin/esphome config firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml > /dev/null
.venv-v0.3-dev/bin/esphome compile firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

Proceed only if both commands exit successfully. Build diagnostics and generated C++ may contain credentials; keep them local and review/redact before sharing.

Build directory: `firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/`. Canonical image:

```text
firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
```

Confirm that its generated `platformio.ini` selects board `cbu`, LibreTiny `v1.14.0`, and `custom_versions.beken-bdk = 3.0.78`. Check the UF2 target with the official tool and record its hash:

```bash
ltchiptool uf2 info firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
sha256sum firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
```

These commands assume an existing `ltchiptool` installation on PATH; otherwise use its actual absolute executable path. Back up the exact image and its hash before [flashing](flash.md). Binaries contain credentials and must not be published. The process is pinned and documented; bit-identical rebuilds are not established.
