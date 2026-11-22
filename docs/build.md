# Build the current firmware

Build the ESPHome UF2 for the BlissLights Evolve with a **Tuya CBU / BK7231N** module. [Firmware template](../firmware/esphome/galaxy-evolve-v0.3-dev.yaml)

[ESPHome setup](#install-esphome-for-the-reference-build) · [ltchiptool setup](#install-ltchiptool-for-image-inspection-and-serial-flashing) · [Private configuration](#create-the-private-configuration) · [Build](#validate-and-compile) · [UF2 checks](#inspect-and-record-the-image-before-flashing)

## Reference toolchain

When I created this repository, I built the configuration with the versions below. The ESPHome commit is an **optional reference** for reproducing that build. [Upstream platform update](https://github.com/esphome/esphome/pull/21531)

| Component | Reference version |
| --- | --- |
| ESPHome | `2026.12.0-dev`, commit `602cbff184c105be128a01f8d61994407988a914` |
| LibreTiny | `1.14.0`, selected by ESPHome |
| Beken BDK | `3.0.78`, selected by ESPHome |

Newer ESPHome releases or development revisions may also work. Use a Python version supported by your chosen ESPHome version. Validate and compile your private YAML, then inspect the resulting UF2 before flashing.

## Install ESPHome for the reference build

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/esphome-logo-on-dark.svg">
  <img src="../images/esphome-logo-on-light.svg" alt="ESPHome" width="144">
</picture>

- **Requirements.** Linux, Git, Python **3.12–3.15** with `venv` and `pip`, internet access and space for the toolchain. The Python range applies to the reference commit.
- **Installation.** Run these commands from the repository root. They use ESPHome's own build process and keep this environment separate from any desktop installation.

```bash
python3 --version
git --version
python3 -m venv .venv-v0.3-dev
.venv-v0.3-dev/bin/python -m pip install 'git+https://github.com/esphome/esphome.git@602cbff184c105be128a01f8d61994407988a914'
.venv-v0.3-dev/bin/esphome version
```

Expect version `2026.12.0-dev`. Verify the source commit as well to identify the exact revision. The command below should print `602cbff184c105be128a01f8d61994407988a914`.

```bash
.venv-v0.3-dev/bin/python -c 'import importlib.metadata as m, json; print(json.loads(m.distribution("esphome").read_text("direct_url.json"))["vcs_info"]["commit_id"])'
```

## Install ltchiptool for image inspection and serial flashing

<img src="../images/ltchiptool-icon.png" alt="ltchiptool" width="48" height="48">

ESPHome compiles the firmware. **ltchiptool** inspects the UF2 and writes it through the USB-UART adapter.

- **Existing installation.** Reuse a working installation after checking its path and version.
- **Fresh installation.** From the repository root, set up the CLI in a separate virtual environment under the Git-ignored `.venv/` directory. The CLI is sufficient for all steps in this guide. [Official CLI installation](https://docs.libretiny.eu/docs/flashing/tools/ltchiptool/#installation)
- **Missing `venv` on Debian.** Install the venv package for your Python version. Run `pip` inside the virtual environment and avoid `sudo pip` on system Python.

```bash
python3 -m venv .venv/ltchiptool
.venv/ltchiptool/bin/python -m pip install 'ltchiptool==4.15.0'
.venv/ltchiptool/bin/ltchiptool --version
```

Expect `ltchiptool v4.15.0`. The pin fixes the CLI release. Its Python dependencies can vary, and ESPHome selects the LibreTiny version independently.

### Make ltchiptool available in your terminal

For the installation above, add the executable to `PATH` from the repository root in each new terminal. You can also use its full path. The same executable is used for the remaining build checks, serial flashing and recovery. [Flash guide](flash.md) · [Recovery guide](recovery.md)

```bash
export PATH="$PWD/.venv/ltchiptool/bin:$PATH"
command -v ltchiptool
ltchiptool --version
```

## Create the private configuration

Create a local YAML with restricted permissions. The copy command preserves an existing local file. If you already have one, compare its non-secret settings with the current template and keep its credentials.

```bash
umask 077
cp -n -- firmware/esphome/galaxy-evolve-v0.3-dev.yaml firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
chmod 600 firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

Edit **only the local copy** and fill all five `INSERT_*` placeholders.

| Field | Required value |
| --- | --- |
| `wifi.ssid` | Home Wi-Fi name |
| `wifi.password` | Home Wi-Fi password |
| `wifi.ap.password` | Fallback AP password |
| `api.encryption.key` | Base64-encoded 32-byte API encryption key |
| `ota[0].password` | ESPHome OTA password |

Keep the supplied Wi-Fi, logging and GPIO settings. The projector uses its original hardware MAC. [Wi-Fi behavior](troubleshooting.md#wi-fi-connection) · [Logging](troubleshooting.md#logging) · [GPIO assignments](wiring.md#firmware-pin-assignments)

### Check that the private YAML stays out of Git

```bash
git check-ignore firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
git ls-files -- firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

- `git check-ignore` must print the local path.
- `git ls-files` must return no output for that path. This confirms the private YAML is untracked.

> [!IMPORTANT]
> Build and flash using the private configuration with real values. Keep the resolved YAML out of terminal output, Git and shared files. Build diagnostics and generated C++ can expose credentials. Review and redact them before sharing. Keep firmware binaries private because they contain credentials.

## Validate and compile

Use the ESPHome executable from your chosen installation. The commands below show the reference environment. Continue only after **both commands succeed**.

```bash
.venv-v0.3-dev/bin/esphome config firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml > /dev/null
.venv-v0.3-dev/bin/esphome compile firmware/esphome/galaxy-evolve-v0.3-dev.local.yaml
```

The build directory is `firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/`. The application image is here.

```text
firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
```

## Inspect and record the image before flashing

1. **Check the target.** In the generated `platformio.ini`, confirm board `cbu`. For the reference build, expect LibreTiny `v1.14.0` and `custom_versions.beken-bdk = 3.0.78`. For a newer ESPHome build, record the versions it actually selects.
2. **Inspect the exact UF2.** Run these checks on the file you intend to keep and flash. They only read the local file.

   ```bash
   UF2=firmware/esphome/.esphome/build/galaxy-lamp-v0.3-dev/.pioenvs/galaxy-lamp/firmware.uf2
   ltchiptool flash file "$UF2"
   ltchiptool uf2 info "$UF2"
   stat -c '%s bytes' "$UF2"
   sha256sum "$UF2"
   ```

   | Check | Result |
   | --- | --- |
   | `ltchiptool flash file` | Identifies the file format and target. It performs a file inspection. |
   | `ltchiptool uf2 info` | Displays the UF2 metadata. |
   | `stat` and `sha256sum` | Report the exact byte size and SHA-256 of this image. |

3. **Check the results.** Require a recognized UF2 for **BK7231N / CBU** with metadata matching the toolchain you recorded. Stop on an unknown file format, a different target or conflicting metadata. Use the layout supplied by the verified UF2 and leave raw flash offsets to the tool. Boot and connectivity are checked after flashing.
4. **Back up the image and its record.** Keep the exact UF2, image path, byte size, SHA-256 and versions of ESPHome, LibreTiny, Beken BDK and ltchiptool with your private backup. For an ESPHome installation from Git, also record its commit. Credentials and build information can change the hash even with the reference commit fixed. Use the hash for your own exact image.

Building and inspecting the image are local operations. When the backup and checks are complete, use the flashing guide for serial-port identification, original power supply, laser disconnection, wiring, the CEN handshake and the write command. [Flashing guide](flash.md)
