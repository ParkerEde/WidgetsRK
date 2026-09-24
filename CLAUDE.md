# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Überblick

EdgeTX-Lua-Telemetrie-Widgets RK01–RK05 für Sender mit Farbdisplay (FrSky Horus X10/X12, TX16S), ab EdgeTX 2.10.0. Texte, Kommentare und Doku sind auf Deutsch.

- Repo: `ParkerEde/WidgetsRK` (privat)
- Die Historie wurde aus den früheren Versionsordnern in `C:\MP-Repos\Widgets RK01-05` rekonstruiert. Jeder Ordner ist ein Commit, jede Version ab V1.0.0 hat einen Tag `vX.Y.Z` und ein GitHub Release. Die Ordner bleiben als Archiv liegen und werden nicht mehr gepflegt.

## Build / Test

Es gibt kein Build-System, keinen Linter und keine Tests. Getestet wird nur auf dem Sender oder im EdgeTX-Companion-Simulator. Die `.luac` erzeugt EdgeTX beim Laden selbst. Sie sind per `.gitignore` ausgeschlossen, ebenso die ZIP-Pakete.

## Kodierung – wichtig

- `*.lua` und `*.txt` liegen im Arbeitsverzeichnis als **ISO-8859-1 mit CRLF** vor, so wie sie auf den Sender kommen.
- Ausnahme: `RK-Settings/RK-Settings.lua` ist UTF-8.
- `.gitattributes` (`working-tree-encoding`) speichert die Dateien im Repo als UTF-8, damit GitHub die Umlaute richtig anzeigt.
- Beim Bearbeiten Kodierung und Zeilenenden beibehalten, nicht auf UTF-8 umstellen.

## Neue Version veröffentlichen

1. `local RKWidgetVersion = "x.y.z"` in **allen** `RKxx/main.lua` anheben. Die Nummer steht in der Kopfzeile jedes Widgets.
2. Einen neuen Eintrag oben in `releasenotes.txt` im bestehenden Format (`Version x.y.z` / `=====`) anlegen. Bei geänderten Features oder Sensoren auch `liesmich.txt` anpassen.
3. Doku geändert?
   - Die Quelle ist `docs/RK01-05 Widgets Doku 1.1.x.docx`, dazu gehört das PDF.
   - Die `.md`-Fassung wurde mit mammoth daraus erzeugt und von Hand nachbearbeitet. Sie muss mitgepflegt werden.
4. Commit mit der Betreffzeile `Vx.y.z: <Kurzbeschreibung>`. Den Release-Notes-Text in den Commit-Body übernehmen. Danach den annotierten Tag `vx.y.z` setzen.
5. GitHub Release zum Tag anlegen. gh liegt unter `C:\Progs\gh-cli\bin\gh.exe`, nicht im PATH.
   - Anhängen: `RK Widgets Vx.y.z Installation.zip`, `RK Widgets Vx.y.z Update.zip` und die PDF-Doku.
   - **Installation.zip** enthält: `liesmich.txt`, `RK-Settings/`, alle `RKxx/`, `SOUNDS de Sprachdateien/`, `releasenotes.txt`.
   - **Update.zip** enthält: alle `RKxx/`, `liesmich.txt`, `releasenotes.txt`. Ohne `RK-Settings`, damit die Einstellungen der Nutzer erhalten bleiben.
   - Die bisherigen ZIPs enthielten zusätzlich die vom Sender erzeugten `main.luac`.

## Architektur

SD-Karte: `/WIDGETS/RK01..RK05/main.lua`, `/WIDGETS/RK-Settings/RK-Settings.lua`, WAVs nach `/SOUNDS/de/`.

- **Gemeinsame Einstellungen**: jedes Widget führt beim Laden `loadScript("/WIDGETS/RK-Settings/RK-Settings.lua")()` aus. Die Datei setzt **globale** Variablen:
  - `voiceoutputswitch_1`/`_2`: Ansage-Schalter, Standard `sc`/`sd`
  - `resetswitch`: `ls61`
  - `activate_tracking_switch*`: Motorschutzschalter, Standard `sb`
- **Aufgaben der Widgets**:
  - RK01: Akku, Strom, Kapazität, RPM, Tmp1. Erkennt als einziges die Zellenzahl, nur bei gesichertem Motor. Gibt den Unterspannungsalarm aus.
  - RK02: Höhe und Vario.
  - RK03: GPS, Entfernung, Sats/PDOP.
  - RK04: Top-Bar-Widget für RSSI/VFR bzw. RQly/TQly bei ELRS. Gibt den RSSI-Alarm aus.
  - RK05: Einzelzellen.
  - RK01–03 und RK05 funktionieren nur im Vollbild, kleinere Zonen zeigen „nur Vollbild“.
- **Gemeinsames Muster aller Widgets**:
  - `options`-Tabelle mit den Widget-Einstellungen (TextColor, NoDataColor, …).
  - `getSensors` liest `getValue("Name")`, `"Name-"` und `"Name+"`. Dabei gibt es eine Plausibilitätsprüfung gegen „Mondwerte“, z. B. werden Rohwerte ≥ 1000 verworfen.
  - `savevalues` führt eigene min/max-Kopien (`*minsave`/`*maxsave`), gedrosselt auf einmal pro Sekunde über `getTime()/100`.
  - `resetvalues` setzt alles zurück, wenn sich die RxID ändert (Modellwechsel) oder `resetswitch` > 0 ist. Die RxID kommt von `model.getModule(0)`, bei RxID 0 von Modul 1.
  - `voiceoutput` spielt die Ansagen per `playFile`/`playNumber`.
  - `refreshZone*` zeichnet.
  - `refresh` und `background` rufen dieselben Sammelfunktionen auf, damit auch im Hintergrund Werte erfasst werden.
- **Sensornamen mit Alternativen**: z. B. Kapazität aus `A4` / `EscC` / `Capa` / `Kapa` / `5123`, Sats aus `Sats` / `5100`, PDOP aus `PDOP` / `5101`.
  - Numerische IDs (MSRC, OpenXsensor) werden über `getSourceIndex(CHAR_TELEMETRY.."5123")` gefunden.
  - Ein `...Sensoris...`-Flag merkt sich die gefundene Quelle bis zum nächsten Reset.
  - Die vollständige Liste steht in `liesmich.txt`.
- **Flug-Log über globale Variablen**: wird der Motorschutzschalter nach mindestens 30 s Freigabe wieder gesichert (`trackswitchcondition`), passiert Folgendes:
  1. RK04 legt `/LOGS/<Modell>-<Datum>-<Zeit>_RK-Widget.txt` an, setzt die globale Variable `filename` und `RK04readysaved = 1`.
  2. Danach hängen RK01 → RK02 → RK03 → RK05 nacheinander ihren Abschnitt an. Jedes Widget wartet dabei auf das `RKxxreadysaved`-Flag seines Vorgängers.
  3. Fehlt ein Widget in der Kette auf den Screens, schreiben die folgenden nicht mehr.
  4. Umbenennen von `filename`, `trackswitchcondition`, `RKxxreadysaved` oder der Settings-Variablen bricht die anderen Widgets.
- Viel Code ist in den fünf `main.lua` doppelt vorhanden (`printTable`, `round`, Settings-Lader, Reset-Logik). Gemeinsames Verhalten muss in allen betroffenen Widgets geändert werden.
