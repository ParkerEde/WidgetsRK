-- RK Widgets – Copyright (C) 2022-2026 Ralf Kruse
-- SPDX-License-Identifier: GPL-3.0-or-later
-- +++++++++++ KONFIGURATIONSTEIL Anfang +++++++++++ 
-- es müssen kleine Buchstaben verwendet werden! Die Angabe muss in Anführungszeichen eingefasst sein!

-- Schalter für die Ansage der aktuellen Höhe (ALT) (Schalter nach oben)
-- Schalter für die Ansage der Kapazität (mAh) (Schalter nach unten)
voiceoutputswitch_1 = "sc"

-- Schalter für die Ansage der min/max Werte Strom und Spannung (oben) und der momentan Werte Strom und Spannung (unten)
voiceoutputswitch_2 = "sd"

-- logischer Schalter, mit dem der Reset ausgelöst werden soll
resetswitch = "ls61"

-- Schalter, mit dem die Berechnung der "geflogenen Strecke" gestartet werden soll (z.B. Motorschutzschalter default = "sb")
activate_tracking_switch = "sb"
-- Position angeben, bei dem berechnet werden soll: 1024 = unten ; 0 = mitte ; -1024 = oben
activate_tracking_switch_position = -1024
-- Wenn nur eine Schalterposition ausgeschlossen werden soll dann 1 (und auszuschließende Pos oben angeben), sonst 0
activate_tracking_switch_invers = 1

-- +++++++++++ KONFIGURATIONSTEIL Ende +++++++++++ 