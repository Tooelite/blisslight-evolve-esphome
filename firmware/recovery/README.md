# Recovery A – vollständiger Evolve-Original-Fremddump

**Archivdatei (im privaten Git vorhanden):** `firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz`. **Status:** Übernommen in Commit `ef608ba7`; Git-Blob `c49af721f06ee05c6cc93f53f03b3334fd8b34be`.

**Entpacktes RAW-BIN (nur lokal):** `firmware/recovery/recovery-image.bin`. Diese 2-MiB-Datei wird absichtlich nicht separat in Git abgelegt.

- Archivierter Originalname: `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin`
- Byteumfang: **2.097.152** / `0x200000`
- BIN-SHA-256: `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`
- Archiv-SHA-256: `2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37` (1.637.617 Byte)
- Von **Dawk323** am 17.06.2023 im [Elektroda-Forum, Beitrag #3](https://www.elektroda.com/rtvforum/topic3984240.html) gespendet. **Vielen Dank für das Teilen des Dumps und der ESPHome-Konfiguration!**
- Am 15.11.2026 auf Debian nach Entpacken aus dem vorhandenen privaten Forschungsarchiv hashgeprüft.
- `bk7231tools dissect_dump` mit `ota_1` **und** `ota_big`: Bootloader-RBL bei `0x10F9A` (Header- und Payload-CRC gültig), App bei `0x11000` ohne RBL, Tuya-Speicher ab `0x1EE000`.

**Geplante Recovery:** das vollständige, **unveränderte RAW-BIN adressgleich über FT232/UART mit `ltchiptool flash write -c`** schreiben. RAW-Eingabe ist **kein UF2**. Dateioffset und Flashadresse beginnen beide bei null, Länge `0x200000`. Das überschreibt ausdrücklich auch Bootloader, Tuya-Konfiguration und Geräteidentität. Erst nach separater Flashfreigabe durchführen.

**Verbindliche Schrittfolge und konkreter Befehl:** [docs/recovery.md](../../docs/recovery.md). Keine Abkürzung über App-Scan-Nutzdatenlänge `0xDEAC0`.
