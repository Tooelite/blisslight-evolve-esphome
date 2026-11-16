# Changelog

## v0.3-dev — 2026-11-16

- Current CBU/BK7231N configuration using official ESPHome-dev commit `602cbff184c105be128a01f8d61994407988a914`, with upstream LibreTiny 1.14.0 / Beken BDK 3.0.78 defaults.
- Use `wifi.hidden: true` for an SSID-directed connection without initial scan-based BSSID/channel selection. Retain the original hardware MAC and GPIO assignments.
- Disable ESPHome logging with `level: NONE`, `boot_log_level: NONE` and `baud_rate: 0`.
- Confirmed private build validation, compilation, verified UART transfer, home Wi-Fi connection and encrypted API device-info response identifying this build.
- Publish credential placeholders only; document private local copies and official build/flash commands.
- Retain PCB and adapter illustrations and the unchanged original recovery archive.
