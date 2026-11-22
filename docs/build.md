# Build the current firmware

When I created this repository, I built [`galaxy-evolve-v0.3-dev.yaml`](../firmware/esphome/galaxy-evolve-v0.3-dev.yaml) with ESPHome commit **`602cbff184c105be128a01f8d61994407988a914`** (`2026.12.0-dev`). That build used the upstream defaults of LibreTiny 1.14.0 and Beken BDK 3.0.78 for CBU/BK7231N. [Upstream platform update](https://github.com/esphome/esphome/pull/21531)

The commit is an optional reference for reproducing the original build. Newer ESPHome releases or development revisions may also work. If you choose another version, use a Python version it supports, validate and compile your private YAML, then inspect the resulting UF2 before flashing.

## Install ESPHome for the reference build

Requirements: Linux, Git, Python **3.12–3.15** with `venv`/`pip`, Internet access and enough space for the toolchain. From the repository root:

```bash
python3 --version
git --version
python3 -m venv .venv-v0.3-dev
.venv-v0.3-dev/bin/python -m pip install 'git+https://github.com/esphome/esphome.git@602cbff184c105be128a01f8d61994407988a914'
.venv-v0.3-dev/bin/esphome version
```

The Python range above applies to the reference commit. The commands use ESPHome’s own build process in an isolated environment. The expected version string is `2026.12.0-dev`. The Git commit identifies the exact revision used in this example.

To verify the reference installation, check its source commit (expected: `602cbff184c105be128a01f8d61994407988a914`):

```bash
.venv-v0.3-dev/bin/python -c 'import importlib.metadata as m, json; print(json.loads(m.distribution("esphome").read_text("direct_url.json"))["vcs_info"]["commit_id"])'
```

## Install ltchiptool for image inspection and serial flashing

ESPHome compiles the firmware. **ltchiptool** inspects the resulting image and writes it over the USB-UART adapter; it is not another build system. This guide uses **ltchiptool 4.15.0**. Its version is independent of the LibreTiny version used by ESPHome.

For a fresh Linux/Debian setup, install the CLI in a separate virtual environment from the repository root. The `.venv/` directory is already Git-ignored:

```bash
python3 -m venv .venv/ltchiptool
.venv/ltchiptool/bin/python -m pip install 'ltchiptool==4.15.0'
.venv/ltchiptool/bin/ltchiptool --version
```

Expect `ltchiptool v4.15.0`. This follows the [official CLI installation](https://docs.libretiny.eu/docs/flashing/tools/ltchiptool/#installation) with a fixed version and an isolated Python environment. GUI extras are unnecessary for these terminal instructions. If Python reports that `venv` is unavailable, install the Debian venv package matching your Python interpreter before continuing; do not install packages into the system Python with `sudo pip`.

Make this executable available to the `ltchiptool` commands in this guide, [flash.md](flash.md) and [recovery.md](recovery.md):

```bash
export PATH="$PWD/.venv/ltchiptool/bin:$PATH"
command -v ltchiptool
ltchiptool --version
```

Run this from the repository root in each new terminal, or use the executable's full path instead. If you already have a working installation, check its path and version and reuse it; no reinstall is needed. The version pin fixes the CLI release, not every transitive Python dependency.

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

Keep the supplied Wi-Fi, logging and GPIO settings. The projector uses its original hardware MAC. [Wi-Fi behavior](troubleshooting.md#wi-fi-connection) · [Logging](troubleshooting.md#logging) · [GPIO assignments](wiring.md#firmware-pin-assignments)

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

Use the ESPHome executable from your chosen installation when building with a newer version. Proceed only if validation and compilation both succeed. Build diagnostics and generated C++ may contain credentials. Keep them local and redact them before sharing.

Build directory: `firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/`. Canonical image:

```text
firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
```

## Inspect and record the image before flashing

Check that the generated `platformio.ini` selects board `cbu`. For the reference build, expect LibreTiny `v1.14.0` and `custom_versions.beken-bdk = 3.0.78`. When using a newer ESPHome version, record the versions it actually selects. Use ltchiptool to inspect the exact UF2 you intend to keep and flash. The following commands inspect only the local file.

```bash
UF2=firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
ltchiptool flash file "$UF2"
ltchiptool uf2 info "$UF2"
stat -c '%s bytes' "$UF2"
sha256sum "$UF2"
```

`flash file` detects the file format and intended target; despite its name, it does not write flash. `uf2 info` shows the UF2 metadata. Require a recognized UF2 for **BK7231N / CBU** and check that its build metadata matches the toolchain you recorded. Stop on a different target, an unrecognized file or conflicting metadata; do not compensate by guessing raw flash addresses. Metadata inspection alone does not prove that the device will boot or connect.

Record the image path, byte size, SHA-256, ESPHome version, LibreTiny version, Beken BDK version and ltchiptool version with your private backup. If you installed ESPHome from Git, record the source commit as well. A new build can have a different hash because it embeds credentials and build information; do not substitute a hash from someone else's build.

Back up the exact image and its hash before [flashing](flash.md). That guide covers serial-port identification, original power supply, disconnected laser, wiring, CEN handshake and the write command. Building or inspecting an image does not flash the device. Binaries contain credentials and must not be published. The documented reference procedure fixes the ESPHome source commit. Build hashes can still differ.
