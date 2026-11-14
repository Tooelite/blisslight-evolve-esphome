# Troubleshooting

| Symptom | Check |
|---|---|
| No serial device | USB cable, `lsusb`, `/dev/serial/by-id/` |
| Permission denied | Device permissions and port ownership |
| Loopback fails | Test FT232 adapter with projector disconnected |
| No chip response | GND, crossed TX/RX, voltage, reset/power sequence |
| Image checksum fails | Stop; use the correct unmodified binary |
| CRC write verification fails | Stop; inspect wiring, power and tool output |
| Flash writes but device does not boot | Stop; inspect flash layout and device-specific regions |
