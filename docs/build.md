# Firmware B – vollständiger Evolve-Build mit ESPHome 2024.4.1

**Arbeitsstand v1.0 · 15.11.2026:** Die originale Community-YAML ist vorhanden. Die lokale Konfigurationsprüfung, Kompilierung und Prüfung des erzeugten UF2 sind **noch nicht ausgeführt**. Dieser Weg ist unabhängig vom vollständigen Original-BIN-Recovery.

## 1. Verbindlicher Quellstand

- **Einzige Build-YAML:** [galaxy-evolve-2024-v0.1.yaml](../firmware/esphome/galaxy-evolve-2024-v0.1.yaml), byteidentisch zum bisherigen Forschungsstand (Git-Blob `e099818947b7a7e8f1ae070ffffeae62e026af25`).
- **ESPHome:** exakt **2024.4.1** in einer eigenen Python-Umgebung, nicht das vorhandene ESPHome 2026.
- **LibreTiny:** Git-Commit `d1386a8e9dcdeed4c50dd0628462b14c9295d304` ist bereits in der YAML eingetragen; historisch plausibel, aber nicht als damalige Originalversion nachgewiesen.
- **Funktionen unverändert:** RGBW GPIO6/26/24/9; Sternlaser GPIO8; Motor GPIO7 mit 15 % Mindestleistung; Gerätetaste GPIO14; Status-LED GPIO0; zwei Zufallseffekte. Der möglicherweise fehlerhafte Community-Dimmcode (+5 % in beiden Zweigen) bleibt zunächst originalgetreu.

## 2. WLAN, Access Point und API – lokal hinterlegen

Die YAML enthält die `!secret`-Referenzen bereits. Auf dem Debian-Rechner ausschließlich lokal die Datei `firmware/esphome/secrets.yaml` anlegen:

```yaml
wifi_ssid: "ECHTE_WLAN_SSID"
wifi_password: "ECHTES_WLAN_PASSWORT"
fallback_ap_password: "EIGENES_AP_PASSWORT"
evolve_2024_api_key: "GUELTIGER_BASE64_API_SCHLUESSEL"
evolve_2024_ota_password: "EIGENES_OTA_PASSWORT"
```

Alle Platzhalter müssen vor einem Release-Build durch die **wirklichen Zielwerte** ersetzt werden. Der API-Schlüssel muss zu 32 dekodierten Bytes führen. Die Fallback-AP-SSID in der YAML heißt `Galaxy-Evolve`; sie ist nicht die Heim-WLAN-SSID.

`secrets.yaml` wird von Git ignoriert. Zugangsdaten oder unzensierte `esphome config`-Ausgaben nicht veröffentlichen. Auch das fertige Firmwareimage kann Zugangsdaten enthalten.

## 3. Lokaler Build auf Debian

Aus der Wurzel **dieses** Repositorys:

```bash
python3.11 -m venv ~/esphome-2024-env
~/esphome-2024-env/bin/python -m pip install 'esphome==2024.4.1'
~/esphome-2024-env/bin/esphome version

~/esphome-2024-env/bin/esphome config \
  firmware/esphome/galaxy-evolve-2024-v0.1.yaml

~/esphome-2024-env/bin/esphome compile \
  firmware/esphome/galaxy-evolve-2024-v0.1.yaml
```

Voraussetzung: Eine kompatible `python3.11`-Installation ist lokal verfügbar. **Diese Befehle wurden im Projekt noch nicht erfolgreich ausgeführt.** Nach dem Build die tatsächlichen ESPHome-/PlatformIO-/SDK-Versionen und den konkreten UF2-Dateipfad festhalten. Bei Fehlern stoppen und anhand der Logs eingrenzen – keine eigenmächtige Versionsmigration oder GPIO-/Funktionskürzung.

## 4. UF2 prüfen und später flashen

Vor jeder Flashfreigabe das **neu gebaute UF2** auf BK7231N/CBU-Ziel, Dateiformat, Flashadressierung, Bootloader-Schutz, Größe und Hash prüfen. Auf keinen Fall die alte ESPHome-2026-`firmware.uf2` wiederverwenden.

**Transportsystem:** derselbe erprobte FT232/UART-Weg mit manuellem CEN-Reset und `ltchiptool flash write -c` wie in [wiring.md](wiring.md). Bei UF2 ermittelt `ltchiptool` die Adressierung aus dem UF2 selbst; das ist ausdrücklich **nicht** der RAW-2-MiB-Restore aus [recovery.md](recovery.md).

**Status:** Kein ESPHome-2024-Build, kein geprüftes 2024-UF2, kein Flash. Gerätewrite nur nach gesonderter ausdrücklicher Freigabe.
