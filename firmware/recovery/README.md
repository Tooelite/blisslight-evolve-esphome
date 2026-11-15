# Recovery A – vollständiger Evolve-Original-Fremddump

**Datei (nur lokal):** `firmware/recovery/recovery-image.bin`. Dieses 2-MiB-RAW-BIN wird absichtlich **nicht** in Git abgelegt.

- Archivierter Originalname: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`
- Byteumfang: **2.097.152** / `0x200000`
- SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`
- Am 15.11.2026 auf Debian nach Entpacken aus dem vorhandenen privaten Forschungsarchiv hashgeprüft.
- `bk7231tools dissect_dump` mit `ota_1` **und** `ota_big`: Bootloader-RBL bei `0x10F9A` (Header- und Payload-CRC gültig), App bei `0x11000` ohne RBL, Tuya-Speicher ab `0x1EE000`.

**Geplante Recovery:** das vollständige, **unveränderte RAW-BIN adressgleich über FT232/UART mit `ltchiptool flash write -c`** schreiben. RAW-Eingabe ist **kein UF2**. Dateioffset und Flashadresse beginnen beide bei null, Länge `0x200000`. Das überschreibt ausdrücklich auch Bootloader, Tuya-Konfiguration und Geräteidentität. Erst nach separater Flashfreigabe durchführen.

**Verbindliche Schrittfolge und konkreter Befehl:** [docs/recovery.md](../../docs/recovery.md). Keine Abkürzung über App-Scan-Nutzdatenlänge `0xDEAC0`.
