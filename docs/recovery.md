# Recovery A – vollständigen Evolve-Fremddump per FT232/UART zurückschreiben

**Stand v1.1 · 15.11.2026.** Gewähltes Recovery-Medium ist **das komplette, unveränderte RAW-BIN (0x200000 Byte)** aus einem anderen Evolve-Gerät. Wir verwenden den am Zielgerät erfolgreichen **UART-Transport mit `ltchiptool`**, nicht OTA, Cloudcutter oder einen ungeprüften Web-/WLAN-Upload. **Der vollständige RAW-Flash wurde noch nicht durchgeführt.**

## 1. Quellen- und Speicherbefund – abgeschlossen

| Prüfung | Tatsächliches Ergebnis |
| --- | --- |
| Vollständiger BIN-Dump | 2.097.152 Byte / `0x200000` |
| SHA-256 | `07a76fa01817d4924cebe72b3ebfe789a86bdb3c94418d7570baaf10e1b58da0` – lokal bestätigt |
| `dissect_dump` mit `ota_1` | Bootloader-RBL `0x10F9A`, `NONE`, Payload `0xEA20`; App-Scan `0x11000`, `NO RBL`, extrahierte Nutzdaten `0xDEAC0`; Storage `0x1EE000` |
| `dissect_dump` mit `ota_big` | **Identische Ausgabe** |
| Bootloader-RBL | `bk7231tools` validiert Header-CRC32 und Payload-CRC32; RBL-Header liegt **am Ende** der Bootloaderpartition, nicht am Ausführungsanfang |
| Tuya-Storage | 32 KiB / 12 Schlüssel ab `0x1EE000` |
| Eigenes Main-Backup | `0x011000–0x1EDFFF` (Länge `0x1DD000`) |
| Eigenes Config-Backup | `0x1EE000–0x1FFFFF` (Länge `0x12000`) |
| Eigenes Boot-Backup | **Fehlt** (`0x000000–0x010FFF`) |

Die beiden Parserläufe und der SHA-256-Abgleich wurden am 15.11.2026 auf Debian durchgeführt. Die identischen Ergebnisse trotz unterschiedlicher `ota_1`-/`ota_big`-App-Partitionslängen sind **kein Beleg für die genaue interne OTA-Aufteilung**. Für das gewählte komplette BIN-Image ist keine App-Teilsegmentierung nötig: **Datei-Offset 0 bis 0x1FFFFF entspricht Flashadresse 0 bis 0x1FFFFF.** Die Zahl `0xDEAC0` ist eine CRC-bereinigte App-Nutzdatenlänge, **keine physische Flash-Schreibbereichslänge**. Das betrifft nur eine unzulässige Extraktion/Teilübertragung. Für den gewählten vollständigen RAW-Restore bleibt die unveränderte BIN-Datei mit `-s 0x000000 -S 0x000000 -l 0x200000` maßgeblich. **Nicht kürzen, nicht verschieben, nicht die extrahierten App-Nutzdaten statt des vollständigen BIN verwenden.**

Der gesamte BIN-Dump ist die Recovery-Quelle; weder wird die App herausgeschnitten noch wird aus ihm ein neues UF2 konstruiert. Der Bootloader-RBL ist strukturell intakt, seine tatsächliche Laufzeit auf unserem Evolve wurde **noch nicht getestet**.

## 2. Archiv aus dem Forschungsrepository übernehmen und BIN prüfen

**Quelle:** [Dawk323, Elektroda-Beitrag #3 vom 17.06.2023](https://www.elektroda.com/rtvforum/topic3984240.html). Er stellte den vollständigen Original-BK7231N-Dump `readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin` bereit.

**Archiv im historischen Repository:** `Tooelite/bliss-evolve-android/firmware/references/evolve-reference-firmware-bk7231n-v1.0.tar.gz`.

**Ziel im neuen privaten Repository:** `firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz` (bis zum lokalen Push noch nicht vorhanden).

Archivgröße **1.637.617 Byte**, Archiv-SHA-256 **`2665124ef072fe579b4f38f85e39352cd08a35a0b71167b4706e0e39b40b6d37`**. Der unkomprimierte BIN-Inhalt hat die oben dokumentierte Größe und SHA-256. Die aktuelle `.gitignore` unterdrückt nur entpackte BIN-/UF2-/RBL-Dateien, nicht das `tar.gz`-Archiv.

Nach dem manuellen Kopieren/Pushen des Archivs: Aus der Wurzel dieses Recovery-Repositories den **BIN-Inhalt unverändert** extrahieren und prüfen:

```bash
tar -xOzf firmware/recovery/evolve-reference-firmware-bk7231n-v1.0.tar.gz \
  --wildcards '*readResult_BK7231N_QIO_bliss_2023-14-6--12-56-58.bin' \
  > firmware/recovery/recovery-image.bin

python3 scripts/check-image.py firmware/recovery/recovery-image.bin
```

Das Prüfskript kontrolliert **Größe und SHA-256 des gesamten BIN**; nur bei `PASS` fortfahren. `firmware/recovery/recovery-image.bin` bleibt lokal und wird nicht committed. Das neue Repository ist derzeit privat; vor einer möglichen öffentlichen Freigabe sind Weitergaberechte sowie im Fremddump enthaltene Identitäts- oder Zugangsdaten zu prüfen. Keine zusätzlichen Checksum-Gates für die YAML.

## 3. Waveshare-UART und Bootloader-Einstieg

Verwende **denselben bewährten FT232-UART-Adapter** und `~/esphome-env/bin/ltchiptool` wie beim vorherigen UF2-Schreibvorgang. Setup und reale Anschlüsse stehen in [wiring.md](wiring.md): FT232 TXD → BK7231N RX1/P10 (GPIO10), FT232 RXD → TX1/P11 (GPIO11), gemeinsame Masse, **3,3-V-Logik**. Versorgung separat sicherstellen; keine unkontrollierte Speisung über FT232.

**Resetleitung:** Verbindungsvorgang starten, verifiziertes **CEN kurz auf GND ziehen**, dann lösen. Dadurch antwortet der BK7231N-Bootloader am UART. CEN nicht dauerhaft erden. Keine RTS/CTS-Flusskontrolle.

Vor jedem Schreibversuch Chip und Flashgröße identifizieren:

```bash
~/esphome-env/bin/python -m pip show ltchiptool bk7231tools
~/esphome-env/bin/ltchiptool flash info bk7231n -d /dev/ttyUSB0
```

Erwartet: **BK7231N und 2 MiB**. Bei Verbindungsfehler, anderem Chip oder abweichender Größe **STOP**. Frühere Schreibprotokolle belegen einen erfolgreichen UART-Transfer mit `ltchiptool flash write -d /dev/ttyUSB0 -c ...firmware.uf2` (`Success! Chip info: BK7231N`; `Finished in 70.966 s`), jedoch keine stabile Ausführung dieses ESPHome-2026-Images.

## 4. RAW-Full-Restore – vorgesehener Befehl, noch nicht freigegeben

**Der vollständige Flash ist eine bewusste Entscheidung:** Die 2 MiB ersetzen **Bootloader, Anwendung, Tuya-Storage, Geräteidentität und Kalibrierdaten**. Das Fremdimage ist nicht das Originalbackup unseres Einzelgeräts. Der eigene Bootbereich wurde nie gesichert; nach einer fehlerhaften Übertragung oder inkompatiblen Bootloader-Ersetzung könnte der bisherige serielle Wiederherstellungsweg entfallen.

Nach **expliziter Flashfreigabe**, positivem BIN-Check, überprüfter Verdrahtung und korrekter Chipkennung lautet der aus dem Quellcode abgeleitete Schreibaufruf (im Wurzelverzeichnis dieses Repositorys):

```bash
~/esphome-env/bin/ltchiptool flash write \
  -d /dev/ttyUSB0 \
  -f bk7231n \
  -s 0x000000 \
  -S 0x000000 \
  -l 0x200000 \
  -c \
  firmware/recovery/recovery-image.bin
```

**Adresszuordnung:** Eingabe-Datei ab `0x000000` → Ziel-Flash ab `0x000000`, 2.097.152 Byte. Die Parameter `-f` und `-s` erzwingen den RAW-BIN-Pfad und unterdrücken UF2-Autodetektion. **Kein Offset-Versatz, keine andere Länge und keine UF2-Konvertierung.**

**Verify bereits implementiert:** `-c` aktiviert CRC beim Schreiben in 4-KiB-Sektoren; der BK7231N-Treiber wiederholt fehlgeschlagene Sektor-Schreibvorgänge standardmäßig bis zu drei Mal und meldet danach Fehler. Leere `0xFF`-Blöcke werden nur gelöscht; deshalb nicht als vollständigen, unabhängigen Readback bezeichnen. **Kein automatisches Gesamt-Reflashen und kein verpflichtender Full-Dump-Verify.**

Der RAW-Schreibpfad startet anschließend **nicht** selbstständig die neue Firmware; nach erfolgreichem Ende und gelöster Resetleitung das Gerät kontrolliert neu starten.

## 5. Abnahme

Seriellen Start/Boot, stabile Licht-/Laser-/Motorfunktionen, Tasten, WLAN-Verhalten und Neustart nach Spannungsunterbrechung prüfen. **Geschriebene Bytes allein sind kein Funktionsnachweis.** Auch die Original-Firmware könnte von inzwischen nicht verfügbaren Tuya-/BlissLights-Servern abhängen.

**Status:** vollständiger Dump identifiziert, Bootloader-RBL samt CRC nachgewiesen, beide Parserlayouts verglichen, passende RAW-Schreibfunktion im `ltchiptool`-Quellcode gefunden. Der vollständige Restore wurde **noch nicht freigegeben oder ausgeführt**.

**Quellcode-Nachweise:** `libretiny-eu/ltchiptool` (`ltchiptool/commands/flash/write.py`, `ltchiptool/soc/bk72xx/flash.py`); `tuya-cloudcutter/bk7231tools` (`bk7231tools/serial/cmd_ll_flash.py`, `cmd_hl_flash.py`, `analysis/rbl.py`, `analysis/flash.py`).
