# BlissLights Evolve – technische Reinschrift v1.3

**Gerät:** BlissLights Evolve SKY-EVOLVE-B-RCWB, Tuya CBU / BK7231N, 2 MiB Flash.

Dieses Repository ist ab 15.11.2026 die **verbindliche, bereinigte Arbeitsgrundlage** für Wiederherstellung, ESPHome-Firmwarebau und Waveshare-FT232-Anschluss. Das frühere Repository `Tooelite/bliss-evolve-android` dient als **Quellen- und Belegarchiv** (historische Logs, eigene Teilbackups, fremder Firmwaredump), nicht mehr als maßgebliche Recovery-Anleitung. Kein Vermischen von alter Android-/Tuya-Forschung mit diesen Verfahren. **Übergang:** Der erste ESPHome-2024.4.1-Testbuild wird noch im lokalen alten Repository ausgeführt; die geprüfte Anleitung und spätere erfolgreiche Korrekturen werden hier verbindlich dokumentiert.

## Zwei getrennte Firmwarewege

| Weg | Quelle | Zweck | Stand |
| --- | --- | --- | --- |
| **A · Original-Recovery** | Vollständiger 2-MiB-Community-BIN-Dump | Wiederherstellung der originalen Beken/Tuya-Firmware | BIN identifiziert, Bootloader-RBL geprüft, UART-Rohschreiben im Werkzeugcode belegt; **noch nicht am Gerät ausgeführt** |
| **B · Eigene ESPHome-Firmware** | `firmware/esphome/galaxy-evolve-2024-v0.1.yaml` | Lokale RGBW-, Laser-, Motor- und Tastensteuerung | Quellstand gesichert; **englische Buildanleitung v1.3 mit Python-Autodetektion; lokaler Build noch offen** |

Beide Wege verwenden denselben **Waveshare 6170 / FT232 → BK7231N UART1**-Zugang, manuelles CEN-Reset und `ltchiptool flash write -c`. Für **A** ist das Eingabeformat **RAW BIN** mit expliziten Adressen; für **B** ist es ein erst noch zu bauendes **UF2** mit dessen Mapping. **Nicht verwechseln.**

## Einzige aktuellen Anleitungen

- [A – Recovery aus dem vollständigen Original-Fremddump](docs/recovery.md)
- [B – ESPHome 2024.4.1: English build procedure, local secrets, Python autodetection, validation, compile and UF2 QA](docs/build.md)
- [Waveshare 6170: 3,3-V-UART, Verdrahtung, CEN/Reset und Debian](docs/wiring.md)
- [Fehlerfälle](docs/troubleshooting.md)

## Nachgewiesener Ist-Zustand

Am 14.11.2026 wurde über FT232/UART ein anderes **ESPHome-2026-UF2** mit `ltchiptool flash write -c` übertragen; Chipkennung `BK7231N`, Werkzeugabschluss nach 70,966 s. Der AP erschien nur kurz; **stabiler Betrieb war nicht nachgewiesen**. Dies ist ein Transportnachweis, keine erfolgreiche Firmware-Wiederherstellung.

**Original-Recovery-BIN:** 2.097.152 Byte, SHA-256 `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0`. Das lokal extrahierte Bild wurde am 15.11.2026 hashgeprüft. `bk7231tools dissect_dump` ergibt für `ota_1` und `ota_big` **identisch**: CRC-valider Bootloader-RBL bei `0x10F9A`, App-Scan ab `0x11000` ohne RBL (extrahierte Nutzdaten `0xDEAC0`), Tuya-Storage ab `0x1EE000`. **Nicht die Größe der App-Nutzdaten als Flash-Schreibbereich verwenden.**

**Zielgeräte-Backups:** Main `0x11000–0x1EDFFF` (1.953.792 B), Config `0x1EE000–0x1FFFFF` (73.728 B). Der eigene Bootloaderbereich `0x00000–0x10FFF` fehlt als Backup.

**Archivierung:** Das Repository ist derzeit **privat**. Das unveränderte Original-`tar.gz` ist seit Commit `ef608ba7` unter `firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz` hinterlegt (1.637.617 Byte, Git-Blob `c49af721f06ee05c6cc93f53f03b3334fd8b34be`). Das extrahierte RAW-BIN bleibt außerhalb der Git-Historie. **Vor einer möglichen öffentlichen Freigabe** sind Urheber-/Weitergaberechte und gerätespezifische Daten des Fremddumps zu klären.

**Flashrisiko:** Der geplante vollständige RAW-Restore überschreibt sämtliche 2 MiB **einschließlich Bootloader und gerätespezifischer Daten**. Ein solcher Write erfolgt ausschließlich nach expliziter Freigabe. Bisher weder Original-Recovery noch ESPHome-2024-Flash ausgeführt.

## Credits und Dank

**Vielen Dank an [Dawk323](https://www.elektroda.com/rtvforum/topic3984240.html)** für die Veröffentlichung des vollständigen BK7231N-Evolve-Firmwaredumps am **17.06.2023 (Beitrag #3)** sowie für das Teilen der ESPHome-Galaxy-Evolve-YAML am **27.04.2024 (Beitrag #13)**. Ohne diese Beiträge wären der Original-Recovery-Ansatz und die Rekonstruktion der lokalen Projektorsteuerung deutlich schwieriger.

Vielen Dank auch an **helge1** für den dokumentierten Praxistest der ESPHome-Konfiguration am **29.06.2024 (Beitrag #14)**.

Die Quelle ist das [Elektroda-Forum zum BlissLights Evolve](https://www.elektroda.com/rtvforum/topic3984240.html); die Nennung stellt keine Aussage über eine erteilte Lizenz zur Weiterveröffentlichung der Hersteller-Firmware dar.

## Änderungsverlauf

- **v1.0 (15.11.2026):** Zwei getrennte Firmwarewege, Quellen und Analysestand konsolidiert.
- **v1.1 (15.11.2026):** Firmware-Spender und Community-Praxistest mit Quellen genannt; Archivübernahme vorbereitet und Bedeutung von `0xDEAC0` präzisiert.
- **v1.2 (15.11.2026):** Englische ESPHome-2024.4.1-Buildanleitung mit isolierter Umgebung, echten lokalen Secrets, geschützten Logs, UF2-QS und Flashfreigabe festgehalten. Vollständiges Fremd-BIN-Archiv liegt in Git.
- **v1.3 (15.11.2026):** Fehler `python3.11: command not found` auf Debian erfasst; tatsächlich installiertes `/usr/bin/python3` ist 3.13.5. [Automatisch erkennendes Buildskript](scripts/build-esphome-2024.sh) und englische Anleitung statt hartcodierter Python-Version. Keine Firmware gebaut oder geflasht.
