# Recovery steps

1. Install Linux tools: `sudo apt-get install -y python3-venv python3-pip usbutils` and `bash scripts/setup-linux.sh`.
2. Extract the reference community binary from the source repository archive and place it at `firmware/recovery/recovery-image.bin`.
3. Check it: `python3 scripts/check-image.py firmware/recovery/recovery-image.bin`.
4. Configure and test the Waveshare FT232 as described in [wiring.md](wiring.md).
5. Verify the actual projector UART pads, I/O voltage, power/reset procedure, image layout and device-specific flash regions **before any write**.
6. Check the installed tool options with `.venv/bin/ltchiptool flash write --help`; use only a reviewed command and explicit authorization.
7. After flashing, check boot, projector output, controls, Wi-Fi and power cycling.

The source repository documents a successful UART write using `ltchiptool`, but this is not evidence that writing the entire foreign 2 MiB image is safe.
