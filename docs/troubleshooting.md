# Troubleshooting

- No `/dev/ttyUSB*`: inspect `lsusb`, USB cable, kernel messages and `/dev/serial/by-id/`.
- Permission denied: inspect `ls -l /dev/ttyUSB0`, user groups and other processes. Do not apply broad device permissions as a default.
- Loopback fails: disconnect the projector, test the adapter and port alone.
- Handshake fails: stop; verify voltage, GND, RX/TX crossover, power and reset timing. Do not start writing.
- Checksum mismatch: stop; preserve both files and compare against the source archive.
- CRC retries exhausted: stop; inspect electrical stability and tool logs. Do not repeatedly reflash the whole chip.
- Flash completes but device fails: do not claim recovery. Preserve logs and investigate image layout, boot region, configuration and power.
