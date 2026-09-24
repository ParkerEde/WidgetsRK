# RK Widgets (RK01–RK05)

Telemetrie-Widgets für EdgeTX-Sender mit Farbdisplay: Akku, Strom, Kapazität, Höhe/Vario, GPS, Linkqualität und Einzelzellen übersichtlich auf je einer Vollbildseite, mit Sprachansagen, Warnungen und einem Flug-Log auf der SD-Karte.

<p>
  <img src="docs/img/bild09.png" alt="RK01: Akku, Strom, Kapazität" width="400">
  <img src="docs/img/bild07.png" alt="RK03: GPS" width="400">
</p>

| Widget | Platzierung | Inhalt |
|---|---|---|
| RK01 | Vollbild | RxBat, LiPo gesamt und pro Zelle, Strom, Watt, Kapazität, RPM, Tmp1, Zellenzahl-Erkennung, Unterspannungsalarm |
| RK02 | Vollbild | Höhe, Vario (m/s und km/h), max. Steigen/Sinken |
| RK03 | Vollbild | GPS: Geschwindigkeit, Höhe NN/über Grund, Entfernung, Satelliten, PDOP, Start-/Modellposition, geflogene Strecke |
| RK04 | Top-Bar | RSSI/VFR bzw. RQly/TQly (ELRS), verzögerte RSSI-Warnung |
| RK05 | Vollbild | Einzelzellenspannungen aus Cels/Cel2 (FrSky MLVSS, FLVSS, FLVS-ADV) |

## Funktionen

- Momentan- und min/max-Werte je Sensor. Fehlen Daten, erscheinen die Werte in der NoData-Farbe bzw. als `- -`.
- Plausibilitätsprüfung: offensichtlich falsche Telemetriewerte („Mondwerte“) werden verworfen.
- Sprachansagen über die Schalter SC/SD: Höhe, Kapazität, Strom und Zellenspannung, mit einstellbarer Wiederholzeit.
- Warnungen: Unterspannung pro Zelle (RK01), RSSI/Linkqualität (RK04), Ansage beim GPS-Fix (RK03).
- Automatische Zellenzahl-Erkennung bis 12S, solange der Motor gesichert ist.
- Kapazität vom Sensor (A4, EscC, Capa, Kapa oder MSRC 5123) oder im Widget aus dem Strom berechnet.
- Reset aller min/max-Werte per logischem Schalter (Standard LS61) oder automatisch beim Modellwechsel.
- Flug-Log: Wird der Motorschutzschalter nach mindestens 30 s Freigabe wieder gesichert, schreiben die Widgets eine Zusammenfassung des Flugs nach `/LOGS/<Modell>-<Datum>-<Zeit>_RK-Widget.txt`.

## Voraussetzungen

- **Sender:** EdgeTX **2.10.0 oder neuer**, Farbdisplay 480×272.
  - Getestet auf Radiomaster TX16S und FrSky Horus X10(S)/X12(S).
  - Andere Sender mit diesem Display sollten ebenfalls funktionieren.
- **Empfänger-ID:** Das HF-Modul (intern oder extern) muss aktiv sein und die Empfänger-ID darf nicht 0 sein. Sonst funktionieren der Reset und die Erkennung des Modellwechsels nicht.
- **Reset-Schalter:** ein logischer Schalter, Standard LS61.
- **Telemetrie:** Sensoren je nach Widget. Die Widgets erkennen diese Sensornamen:
  - Empfänger und Link: `RSSI`, `VFR`, `RQly`, `TQly`, `RxBt`
  - Akku und Antrieb: `VFAS`, `Curr`, `A4`/`EscC`/`Capa`/`Kapa`/`5123`, `RPM`, `Tmp1`, `Cels`, `Cel2`
  - Höhe: `Alt`, `VSpd`
  - GPS: `GPS`, `GAlt`, `GSpd`, `Sats`/`5100`, `PDOP`/`5101`

  Die Zahlen sind die IDs aus MSRC bzw. OpenXsensor.

## Installation

Die fertigen Pakete gibt es unter **[Releases](../../releases)**:

- **Installation.zip**: vollständiges Paket für die Erstinstallation
- **Update.zip**: nur die Widgets und `RK-Lib`, ohne `RK-Settings`, damit die eigenen Einstellungen erhalten bleiben

Auf die SD-Karte kopieren:

- `RK01` … `RK05`, `RK-Lib` und `RK-Settings` nach `/WIDGETS/`
- den Inhalt von `SOUNDS de Sprachdateien` nach `/SOUNDS/de/`

`RK-Lib` enthält die gemeinsamen Funktionen und muss immer dieselbe Version wie die Widgets haben. Sonst zeigen die Widgets einen roten Hinweis statt der Werte.

Danach auf dem Sender:

- RK01, RK02, RK03 und RK05 jeweils einer eigenen Vollbild-Seite zuweisen.
- RK04 zweimal einem Top-Bar-Feld zuweisen, einmal mit der Option `ShowVFR`.
- Die Schalter für Ansagen, Reset und Motorschutz stehen in `/WIDGETS/RK-Settings/RK-Settings.lua` und lassen sich am PC ändern. Standard: SC, SD, LS61 und SB.

Sensoreinrichtung und alle Funktionen im Detail stehen in [liesmich.txt](liesmich.txt) und in der [Dokumentation](docs/RK01-05%20Widgets%20Doku.md). Eine PDF-Fassung je Versionsreihe liegt im Ordner [docs](docs) und hängt am jeweiligen Release.

## Fragen, Fehler, Wünsche

Bitte als [Issue](../../issues) melden. Hilfreich sind:
- die Sender- und EdgeTX-Version
- die Sensoren
- bei Script-Fehlern die genaue Meldung vom Display

## Versionen

Jede Version ist ein Commit mit Tag `vX.Y.Z`. Was sich geändert hat:

- [releasenotes.txt](releasenotes.txt): Änderungen je Version
- [Releases](../../releases): Notes und Downloads je Version
- Code-Unterschied zwischen zwei Versionen: z. B. [v1.1.10...v1.2.0](../../compare/v1.1.10...v1.2.0)

Die Historie vor V1.0.0 (Februar 2022 bis Januar 2023) ist als einzelne Commits ohne Tag enthalten.

## Entwicklung

- Getestet wird am Sender.
- Vor jeder Änderung läuft außerdem ein Vergleichstest unter [test/](test). Er bildet die EdgeTX-API in Lua 5.2 nach und vergleicht Anzeige, Ansagen und Log-Datei der neuen Fassung mit einem früheren Stand.
- Einrichtung und Aufruf stehen in `test/harness.py`.

## Lizenz

Copyright (C) 2022-2026 Ralf Kruse

Dieses Programm ist freie Software: Du kannst es unter den Bedingungen der GNU General Public License, Version 3 oder (nach deiner Wahl) jeder späteren Version, weitergeben und/oder ändern. Es wird in der Hoffnung verbreitet, dass es nützlich ist, aber ohne jede Gewährleistung. Details stehen in [LICENSE](LICENSE).
