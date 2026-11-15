# Troubleshooting

| Problem | Check |
| --- | --- |
| USB serial adapter not detected | `lsusb -d 0403:6001`, `/dev/serial/by-id/`, cable and FTDI driver |
| Port is busy or access is denied | User membership in `dialout`, `fuser /dev/ttyUSB0`, close other serial applications |
| FT232 loopback fails | Disconnect the projector, connect adapter TXD to RXD, check 3.3 V I/O and the loopback tool |
| BK7231N does not respond | Common GND, crossed UART1 RX/TX, stable power, momentary CEN-to-GND reset during connection |
| Raw image hash or size mismatch | Stop; use only the complete, unmodified 2 MiB dump |
| Chip type or flash capacity differs | Stop; do not write to a mismatched target |
| Flash sector CRC repeatedly fails | Stop; inspect wiring, supply voltage and flash address before retrying |
| Transfer completes but device fails to boot | Transfer success does not prove a compatible bootloader or functional application |
| Original cloud features do not work | Verify the external services independently |
| ESPHome config or compile fails | Inspect the isolated build environment, source YAML, secrets and private phase logs |
| Review log is unavailable | Check that all five secrets can be parsed by the redaction helper; never share the raw private logs instead |

See [ESPHome build](build.md), [complete raw recovery](recovery.md) and [FT232 wiring](wiring.md).
