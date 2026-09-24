# RK Widgets (RK01–RK05)

Telemetrie-Widgets für EdgeTX-Sender mit Farbdisplay (FrSky Horus X10(S)/X12(S), Radiomaster TX16S o. ä.), ab EdgeTX 2.10.0.

| Widget | Platzierung | Inhalt |
|---|---|---|
| RK01 | Vollbild | RxBat, LiPo gesamt und pro Zelle, Strom, Watt, Kapazität, RPM, Tmp1, Zellenzahl-Erkennung, Unterspannungsalarm |
| RK02 | Vollbild | Höhe, Vario (m/s und km/h), max. Steigen/Sinken |
| RK03 | Vollbild | GPS: Geschwindigkeit, Höhe NN/über Grund, Entfernung, Satelliten, PDOP, Start-/Modellposition, geflogene Strecke |
| RK04 | Top-Bar | RSSI/VFR bzw. RQly/TQly (ELRS), verzögerte RSSI-Warnung |
| RK05 | Vollbild | Einzelzellenspannungen aus Cels/Cel2 (FrSky MLVSS, FLVSS, FLVS-ADV) |

## Installation

Die fertigen Pakete gibt es unter **[Releases](../../releases)**:

- **Installation.zip**: vollständiges Paket für die Erstinstallation
- **Update.zip**: nur die Widgets und `RK-Lib`, ohne `RK-Settings`, damit die eigenen Einstellungen erhalten bleiben

Auf die SD-Karte kopieren:

- `RK01` … `RK05`, `RK-Lib` und `RK-Settings` nach `/WIDGETS/`
- `RK-Lib` enthält die gemeinsamen Funktionen und muss immer dieselbe Version wie die Widgets haben. Sonst zeigen die Widgets einen roten Hinweis.
- den Inhalt von `SOUNDS de Sprachdateien` nach `/SOUNDS/de/`

Voraussetzungen, Sensoreinrichtung und alle Funktionen stehen in [liesmich.txt](liesmich.txt) und in der [Dokumentation](docs/RK01-05%20Widgets%20Doku%201.1.x.md). Eine PDF-Fassung liegt im Ordner [docs](docs) und hängt an jedem Release.

## Versionen

Jede Version ist ein Commit mit Tag `vX.Y.Z`. Was sich geändert hat:

- [releasenotes.txt](releasenotes.txt): Änderungen je Version
- [Releases](../../releases): Notes und Downloads je Version
- Code-Unterschied zwischen zwei Versionen: z. B. [v1.1.08...v1.1.09](../../compare/v1.1.08...v1.1.09)

Die Historie vor V1.0.0 (Februar 2022 bis Januar 2023) ist als einzelne Commits ohne Tag enthalten.
