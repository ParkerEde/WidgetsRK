# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Überblick

EdgeTX-Lua-Telemetrie-Widgets RK01–RK05 für Sender mit Farbdisplay (FrSky Horus X10/X12, TX16S), ab EdgeTX 2.10.0. Texte, Kommentare und Doku sind auf Deutsch.

- Repo: `ParkerEde/WidgetsRK` (privat)
- Die Historie wurde aus den früheren lokalen Versionsordnern (`NN Vx.y.z <Beschreibung>`) rekonstruiert. Jeder Ordner ist ein Commit, jede Version ab V1.0.0 hat einen Tag `vX.Y.Z` und ein GitHub Release. Die Ordner bleiben als Archiv liegen und werden nicht mehr gepflegt.

## Build / Test

Es gibt kein Build-System und keinen Linter. Die `.luac` erzeugt EdgeTX beim Laden selbst. Sie sind per `.gitignore` ausgeschlossen, ebenso die ZIP-Pakete.

Der Nutzer testet jede Änderung am Sender. Davor läuft der Vergleichstest unter `test/`:
- `mock.lua` bildet die EdgeTX-API in Lua 5.2 nach (lcd, play, io, getValue, model, loadScript). Alle Zeichen-, Ansage- und print-Aufrufe werden aufgezeichnet.
- `harness.py <szenario> [git-ref]` lässt den Stand aus dem Git-Ref (Standard `main`) und das Arbeitsverzeichnis mit demselben Szenario laufen. Verglichen werden die Aufzeichnung und die geschriebenen Log-Dateien.
  - `--sichtbar`: nur sichtbare Zeichenbefehle mit wirksamer Farbe vergleichen. Leere `drawText("")` und `setColor` zählen nicht.
  - `-e "ALT=>NEU"`: gewollte Änderung in der Aufzeichnung des Git-Refs ersetzen.
  - `-x "ZEILE"`: Aufzeichnungszeile in beiden Fassungen entfernen, z. B. `-x "print | "`.
- `libcheck.py [RKxx ...]` prüft für jedes Widget die Fälle „RK-Lib fehlt“, „RK-Lib-Version falsch“ und „passt“.
- Szenarien: `scen_rk01_sensor.lua`, `scen_rk01_berechnet.lua`, `scen_rk02.lua` … `scen_rk05.lua`, `scen_rk04_allein.lua`. Ein Szenario zeigt nur, was es abdeckt. Bei neuen Fällen das Szenario erweitern.
- Einrichtung einmalig außerhalb des Repos: `python -m venv %TEMP%\rk-luatest`, dann `%TEMP%\rk-luatest\Scripts\python -m pip install lupa`.
- Aufruf aus dem Repo-Ordner: `%TEMP%\rk-luatest\Scripts\python test\harness.py test\scen_rk05.lua --sichtbar`

## Kodierung – wichtig

- Alle `*.lua` und `*.txt` sind **UTF-8 ohne BOM mit CRLF**. Das gilt im Repo und auf dem Sender.
- **Kein BOM**: Es ist nicht geklärt, ob der Lua-Lader von EdgeTX ein BOM überspringt.
- Die Zeilenenden setzt `.gitattributes` (`eol=crlf`).
- Bis V1.1.09 waren die Dateien ISO-8859-1. Ausnahme war `RK-Settings.lua`, die schon UTF-8 war. Die UTF-8-Fassung wurde am Sender getestet. Die Widgets laden normal, und `°C` steht im Flug-Log richtig.
- Auf dem Display gibt EdgeTX keine Umlaute richtig aus. Deshalb in angezeigten Texten keine Umlaute verwenden. In Kommentaren, `print` und Log-Texten sind sie erlaubt.

## Neue Version veröffentlichen

1. Die Version an **sechs** Stellen gleich anheben: `local RKWidgetVersion = "x.y.z"` in allen `RKxx/main.lua` und `lib.version = "x.y.z"` in `RK-Lib/RK-Lib.lua`. Weichen sie ab, zeigt jedes Widget nur den roten Lib-Hinweis. Die Nummer steht in der Kopfzeile jedes Widgets.
2. Einen neuen Eintrag oben in `releasenotes.txt` im bestehenden Format (`Version x.y.z` / `=====`) anlegen. Bei geänderten Features oder Sensoren auch `liesmich.txt` anpassen.
3. Doku geändert?
   - Die einzige Quelle ist `docs/RK01-05 Widgets Doku.md` (ohne Version im Namen), Bilder unter `docs/img/`. Word-Dateien gibt es seit V1.2.0 nicht mehr.
   - **Bildschirmfotos vor dem Einchecken auf persönliche Daten prüfen**, vor allem auf echte GPS-Koordinaten (RK03-Seite, Log-Dateien). Im Zweifel fiktive Werte einsetzen.
     - Die Word-/PDF-Doku bis V1.1.x wurde deshalb am 2026-09-25 komplett aus der Historie entfernt, und die Historie wurde neu geschrieben. `bild07`/`bild11` zeigen fiktive Koordinaten.
   - Die PDFs sind Momentaufnahmen je Versionsreihe x.Y: `docs/RK01-05 Widgets Doku 1.2.x.pdf` usw. PDFs älterer Reihen nie überschreiben.
     - Bei einer neuen Reihe (z. B. 1.3.0) ein neues PDF anlegen.
     - Innerhalb einer Reihe das PDF der Reihe neu erzeugen.
   - Erzeugen: `%TEMP%\rk-luatest\Scripts\python tools\md2pdf.py "docs\RK01-05 Widgets Doku.md" "docs\RK01-05 Widgets Doku x.y.x.pdf" --version x.y.z`. Das Skript geht über Markdown → HTML → Edge/Chrome headless und braucht das Paket `markdown` in der Test-Umgebung.
   - Das PDF der aktuellen Reihe wird ans Release angehängt.
4. Commit mit der Betreffzeile `Vx.y.z: <Kurzbeschreibung>`. Generell gilt für Commits und PRs: **keine** `Co-Authored-By: Claude`- oder „Generated with Claude Code“-Zeilen, das ist Wunsch des Autors. Den Release-Notes-Text in den Commit-Body übernehmen. Danach den annotierten Tag `vx.y.z` setzen.
5. GitHub Release zum Tag anlegen. Dafür die GitHub CLI `gh` nutzen. Wo sie liegt, hängt vom Rechner ab, sie ist ggf. nicht im PATH.
   - Anhängen: `RK Widgets Vx.y.z Installation.zip`, `RK Widgets Vx.y.z Update.zip` und die PDF-Doku.
   - **Installation.zip** enthält: `liesmich.txt`, `RK-Lib/`, `RK-Settings/`, alle `RKxx/`, `SOUNDS de Sprachdateien/`, `releasenotes.txt`.
   - **Update.zip** enthält: alle `RKxx/`, `RK-Lib/`, `liesmich.txt`, `releasenotes.txt`. Ohne `RK-Settings`, damit die Einstellungen der Nutzer erhalten bleiben.
   - Die Ordner liegen direkt auf der obersten Ebene des ZIPs, ohne umschließenden Ordner. `test/` gehört nicht in die ZIPs.
   - Die ZIPs bis V1.1.09 enthielten zusätzlich die vom Sender erzeugten `main.luac`, ab V1.1.10 nicht mehr.

## Architektur

SD-Karte: `/WIDGETS/RK01..RK05/main.lua`, `/WIDGETS/RK-Lib/RK-Lib.lua`, `/WIDGETS/RK-Settings/RK-Settings.lua`, WAVs nach `/SOUNDS/de/`.

- **RK-Lib** (ab V1.2.0): Jedes Widget lädt `loadScript("/WIDGETS/RK-Lib/RK-Lib.lua")()`. Die Datei liefert eine Tabelle mit:
  - `version`, `printTable`, `round`
  - `getRxID`: internes Modul, bei RxID 0 das externe
  - `getTrackSwitchCondition`
  - `drawNurVollbild`, `drawHeader`
  - `drawRow(wgt, x, y, label, nodata, aktuell, minmax, nachkomma[, leer])`: Wertezeile mit Werten bei x+130/x+190
  - `drawValue(wgt, y, label, nodata, leer, wert, nachkomma)`: einzelner Wert rechts bei x+390
  - Funktionen, die nur ein Widget braucht, bleiben lokal im Widget, z. B. `drawRowMinMax` in RK02 und `drawPosition` in RK03.
- **Lib-Prüfung**: Jedes Widget vergleicht beim Laden `lib.version` mit `RKWidgetVersion`. Fehlt die Lib oder passt die Version nicht, gilt Folgendes:
  - `refresh` zeigt nur einen roten Hinweis.
  - `background` tut nichts.
  - Beim Laden darf deshalb nichts direkt auf `lib.` zugreifen, nur innerhalb von Funktionen oder hinter der Prüfung.
  - Der Prüfblock steht in jedem Widget einzeln. Die Lib kann sich nicht selbst prüfen.

- **Gemeinsame Einstellungen**: jedes Widget führt beim Laden `loadScript("/WIDGETS/RK-Settings/RK-Settings.lua")()` aus. Die Datei setzt **globale** Variablen:
  - `voiceoutputswitch_1`/`_2`: Ansage-Schalter, Standard `sc`/`sd`
  - `resetswitch`: `ls61`
  - `activate_tracking_switch*`: Motorschutzschalter, Standard `sb`
- **Aufgaben der Widgets**:
  - RK01: Akku, Strom, Kapazität, RPM, Tmp1. Erkennt als einziges die Zellenzahl, nur bei gesichertem Motor. Gibt den Unterspannungsalarm aus.
  - RK02: Höhe und Vario.
  - RK03: GPS, Entfernung, Sats/PDOP. Nutzt die Linkqualität (RSSI bzw. TQly bei ELRS) zur Prüfung, ob Telemetrie da ist.
  - RK04: Top-Bar-Widget für RSSI/VFR bzw. RQly/TQly bei ELRS. Gibt den RSSI-Alarm aus.
  - RK05: Einzelzellen.
  - RK01–03 und RK05 funktionieren nur im Vollbild, kleinere Zonen zeigen „nur Vollbild“.
- **Gemeinsames Muster aller Widgets**:
  - `options`-Tabelle mit den Widget-Einstellungen (TextColor, NoDataColor, …).
  - `getSensors` liest `getValue("Name")`, `"Name-"` und `"Name+"`. Dabei gibt es eine Plausibilitätsprüfung gegen „Mondwerte“, z. B. werden Rohwerte ≥ 1000 verworfen.
  - `savevalues` führt eigene min/max-Kopien (`*minsave`/`*maxsave`), gedrosselt auf einmal pro Sekunde über `getTime()/100`.
  - `resetvalues` setzt alles zurück, wenn sich die RxID ändert (Modellwechsel) oder `resetswitch` > 0 ist. Die RxID kommt von `lib.getRxID()`.
  - `voiceoutput` spielt die Ansagen per `playFile`/`playNumber`.
  - `refreshZone*` zeichnet. Im Vollbild ist jede der 5×2 Zeilen ein Aufruf von `lib.drawRow`/`lib.drawValue`. Freie Plätze stehen als auskommentierte Vorlage `-- lib.drawRow(wgt, x, y, "Label", nodataX, X, Xmaxsave, 0)` da.
  - `refresh` und `background` rufen dieselben Sammelfunktionen auf, damit auch im Hintergrund Werte erfasst werden.
  - Jede Lua-Datei beginnt mit dem Lizenzkopf `-- RK Widgets – Copyright (C) 2022-2026 Ralf Kruse` / `-- SPDX-License-Identifier: GPL-3.0-or-later`. Die Lizenz ist GPLv3 oder später, siehe `LICENSE`.
  - Variablen sind `local`. Global sind nur die Settings-Variablen, `trackswitchcondition`, `filename` und `RKxxreadysaved`.
  - Auskommentierte `-- print(...)`-Zeilen und die auskommentierten Vorlagen sind gewollt und bleiben stehen. Der Nutzer nutzt sie zum Debuggen.
- **Sensornamen mit Alternativen**: z. B. Kapazität aus `A4` / `EscC` / `Capa` / `Kapa` / `5123`, Sats aus `Sats` / `5100`, PDOP aus `PDOP` / `5101`.
  - Numerische IDs (MSRC, OpenXsensor) werden über `getSourceIndex(CHAR_TELEMETRY.."5123")` gefunden.
  - Ein `...Sensoris...`-Flag merkt sich die gefundene Quelle bis zum nächsten Reset.
  - Die vollständige Liste steht in `liesmich.txt`.
- **Flug-Log über globale Variablen**: `trackswitchcondition` setzen RK01, RK03, RK04 und RK05 jeweils selbst über `lib.getTrackSwitchCondition()`. RK02 liest den Wert nur. Wird der Motorschutzschalter nach mindestens 30 s Freigabe wieder gesichert, passiert Folgendes:
  1. RK04 legt `/LOGS/<Modell>-<Datum>-<Zeit>_RK-Widget.txt` an, setzt die globale Variable `filename` und `RK04readysaved = 1`.
  2. Danach hängen RK01 → RK02 → RK03 → RK05 nacheinander ihren Abschnitt an. Jedes Widget wartet dabei auf das `RKxxreadysaved`-Flag seines Vorgängers.
  3. Fehlt ein Widget in der Kette auf den Screens, schreiben die folgenden nicht mehr.
  4. Umbenennen von `filename`, `trackswitchcondition`, `RKxxreadysaved` oder der Settings-Variablen bricht die anderen Widgets.
- Gemeinsames Verhalten gehört in die `RK-Lib`. In jedem Widget doppelt vorhanden sind weiterhin der Settings-Lader, der Lib-Prüfblock, `resetvalues` und die Größenweiche in `refresh`.
