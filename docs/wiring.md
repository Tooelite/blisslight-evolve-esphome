# Waveshare 6170 / FT232 – Verdrahtung und BK7231N-Download-Reset

**Gerät:** BlissLights Evolve CBU/BK7231N. **Adapter:** Waveshare 6170, FT232 USB-UART. Der bisherige Schreibvorgang über `/dev/ttyUSB0` war erfolgreich verbunden. Der tatsächliche Aufdruck und die Revision des konkreten Adapters bestimmen die Jumperstellungen – **USB-ID `0403:6001` allein beweist kein bestimmtes Platinenlayout**.

## 1. Elektrische Einstellung vor Anschluss

- **UART-Logikpegel: 3,3 V**, nicht RS-232 und nicht ungeprüfte 5-V-Logik. Falls VCC und VCCIO separat einstellbar sind, ist **VCCIO** der Logikpegel.
- **Stromversorgung:** Projektor aus seiner geeigneten Versorgung; die VCC/3V3/5V-Leitungen des USB-Adapters **nicht** mit dem Projektor verbinden, solange die Versorgung nicht separat elektrisch geprüft ist.
- **Keine Hardwareflusskontrolle:** RTS/CTS/DTR nicht anschließen; für den dokumentierten Weg CEN manuell nach GND resetten.
- Vor jeder Änderung der Leitungen Stromversorgung trennen; keine spannungsführenden Leiter oder unbekannten Pads kurzschließen.

## 2. Pinbelegung

| Waveshare FT232 | BK7231N / CBU | Bedeutung |
| --- | --- | --- |
| **GND** | **GND** | Gemeinsame Masse |
| **TXD** | **RX1 / P10 / GPIO10** | TX am USB-UART zu RX am Chip |
| **RXD** | **TX1 / P11 / GPIO11** | RX am USB-UART zu TX am Chip |
| **VCC, 3V3, 5V** | **nicht verbinden** | Keine ungeprüfte Versorgung über USB-UART |
| **RTS / CTS / DTR** | **nicht verbinden** | Keine Flow-Control-Leitungen |
| **GND**, kurzzeitig per separater Leitung | **CEN / Reset** | Bootloader-Einstieg durch kurzen Low-Impuls |

**Achtung:** Die elektrische Signalbezeichnung legt **nicht** die physische Position eines Lötpads am konkreten Projektor fest. Die CEN-Leitung muss anhand der realen Platine identifiziert werden. Nur zum Reset kurz CEN mit GND verbinden, **nicht dauerhaft**.

## 3. Debian und FT232 prüfen

Den Adapter zunächst **ohne angeschlossenen Projektor** an USB anschließen:

```bash
lsusb -d 0403:6001
ls -l /dev/serial/by-id/
ls -l /dev/ttyUSB*
lsmod | grep -E '^(ftdi_sio|usbserial)\b' || true
fuser /dev/ttyUSB0 || true
```

Unter Debian ist meist `ftdi_sio` aktiv. Bei fehlenden Rechten `dialout`-Gruppenzugehörigkeit prüfen; nach einer Gruppenänderung neu anmelden. Serielle Monitore müssen vor `ltchiptool` geschlossen sein. `/dev/ttyUSB0` ist der belegte frühere Anschluss, muss beim erneuten Verbinden kontrolliert werden.

**Adapter-only-Loopback:** Projektor abklemmen, FT232-TXD und FT232-RXD vorübergehend miteinander verbinden, dann:

```bash
python3 scripts/waveshare-ft232-loopback.py --port /dev/ttyUSB0 --timeout 3
```

Erwartet: `PASS`. Nur dieser Loopback nutzt fest **115200 8N1, ohne Flow-Control**; das eigentliche Flashwerkzeug wählt ggf. eine andere UART-Datenrate. Jumperbrücke TXD↔RXD anschließend entfernen.

## 4. CEN-Reset im richtigen Moment

1. Verdrahtung wie oben kontrollieren; Projektor mit geeigneter Spannung versorgen und den USB-UART-Anschluss verbinden.
2. **Verbindungsversuch starten** (beispielsweise nur lesend mit dem Chip-Info-Befehl).
3. Während `ltchiptool` auf den BK7231N wartet, **verifiziertes CEN kurz mit GND verbinden und wieder lösen**.
4. Nur bei bestätigtem Chiptyp **BK7231N** und Flashkapazität **2 MiB** fortfahren.

```bash
~/esphome-env/bin/ltchiptool flash info bk7231n -d /dev/ttyUSB0
```

Der ursprüngliche erfolgreiche Schreibvorgang verwendete `~/esphome-env/bin/ltchiptool` und genau diesen UART-Transport. **Keinen neuen USB-UART-Adapter, keine zusätzliche Reset-Automatik und keine andere Toolchain erfinden, solange der vorhandene Weg funktioniert.** Ein Chip-Info-Aufruf schreibt keine Firmware.

Der autorisierte Schreibaufruf steht je nach Dateityp **getrennt** in [Recovery A (RAW BIN)](recovery.md) bzw. [ESPHome B (UF2)](build.md). **Firmwarewrite nur nach ausdrücklicher Freigabe.**
