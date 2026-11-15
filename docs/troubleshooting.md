# Fehlersuche – ausschließlich der dokumentierte FT232/UART-Weg

| Symptom | Gezielte Prüfung |
| --- | --- |
| USB-UART fehlt | `lsusb -d 0403:6001`, `/dev/serial/by-id/`, `ftdi_sio`, Verbindung/USB-Kabel |
| Zugriff verweigert / Port belegt | Benutzergruppe `dialout`, `fuser /dev/ttyUSB0`, andere Programme schließen |
| FT232-Loopback fehlschlägt | Projektor abklemmen, TXD↔RXD brücken, Adapterlogikpegel und Loopbackskript kontrollieren |
| BK7231N antwortet nicht | Masse, gekreuztes RX1/TX1, **3,3-V-Logik**, separate Versorgung und **kurzer CEN→GND-Reset während Verbindungsaufbau** |
| BIN-SHA-256 oder Größe stimmen nicht | Stoppen; nur den nachweislich vollständigen, unveränderten 2-MiB-Dump verwenden |
| `flash info` zeigt falschen Chip/Flashgröße | Stoppen; keine Schreibfreigabe |
| Schreib-CRC schlägt wiederholt fehl | Stoppen; Versorgung, FT232/UART, Fehladresse prüfen; kein ungeprüfter kompletter Wiederholungsflash |
| Übertragung erfolgreich, aber Gerät startet nicht | Übertragungserfolg ≠ lauffähige Firmware; Bootloader und Strom-/Startverhalten prüfen; keine Behauptung „Recovery erfolgreich“ |
| Gerät läuft, aber Original-App/Cloud funktioniert nicht | Funktion der alten externen Tuya-/BlissLights-Dienste gesondert prüfen |
| ESPHome `config`/`compile` fehlerhaft | Build im isolierten ESPHome-2024.4.1-Environment und lokale Secrets prüfen; keine automatischen Versionswechsel |

Beide Firmwarewege bleiben getrennt: [Full-BIN-Recovery](recovery.md), [ESPHome-Build](build.md), [Waveshare-Verdrahtung](wiring.md).
