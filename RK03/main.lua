-- RK Widgets – Copyright (C) 2022-2026 Ralf Kruse
-- SPDX-License-Identifier: GPL-3.0-or-later
local RKWidgetVersion = "1.2.0"
-- +++++++++++ KONFIGURATIONSTEIL Anfang +++++++++++
local settings, err = loadScript ("/WIDGETS/RK-Settings/RK-Settings.lua")
if (settings ~= nil) then
	settings()
else
	print(err)
end
-- +++++++++++ KONFIGURATIONSTEIL Ende +++++++++++

-- gemeinsame Funktionen aller RK-Widgets
-- libfehler ist nil, wenn die RK-Lib geladen ist und zur Widget-Version passt
local lib, liberr = loadScript ("/WIDGETS/RK-Lib/RK-Lib.lua")
local libfehler = nil
if (lib ~= nil) then
	lib = lib()
	if lib.version ~= RKWidgetVersion then
		libfehler = "RK-Lib V" .. tostring(lib.version or "?") .. " passt nicht zu V" .. RKWidgetVersion
	end
else
	libfehler = "RK-Lib fehlt"
	print(liberr)
end
if libfehler ~= nil then print("RK03: " .. libfehler) end
local printTable, round
if libfehler == nil then
	printTable = lib.printTable
	round = lib.round
end

-- Hinweis statt der Werte, wenn die RK-Lib fehlt oder nicht passt
local function drawLibFehler(wgt)
	lcd.setColor(CUSTOM_COLOR, RED)
	if wgt.zone.w > 380 then
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK03: " .. libfehler, SMLSIZE + CUSTOM_COLOR)
	else
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK-Lib Fehler", SMLSIZE + CUSTOM_COLOR)
	end
end

local options = {
	{ "TextColor", COLOR, WHITE },
	{ "NoDataColor", COLOR, BLACK }
}

local function update(wgt, options)
	if (wgt==nil) then
		print("update(nil)")
		return
	end
	wgt.options = options
end

local function create(zone, options)
	local wgt  = { zone=zone, options=options}
	return wgt
end

local ModelRxIDVorher = -1

local RSSI = 0

local GSpd = 0
local GSpdmaxsave = 0

local nodataGAlt = 1
local GAlt = 0
local GAltmaxsave = 0
local GAltOffsetdone = 0
local GAltOffset = 0

local GAl2 = 0
local GAl2maxsave = 0

local DisM = 0
local DisG = 0
local DisMmaxsave = 0
local DisGmaxsave = 0

local gpsfixmessagedone = 0
local Track = 0

local Sats = 0
local Satsraw = 0
local Satssave = 0
local SatsSeen = 0
local PDOP = 0
local PDOPraw = 0
local PDOPsave = 0
local PDOPSeen = 0
local SatsSensor = -1
local PDOPSensor = -1

local timestamprefresh = 0

local function getSensors(wgt)

	if getValue("TQly-") > 0 then
		RSSI = getValue("TQly")
	else
		RSSI = getValue("RSSI")

	end

	local GSpdraw = getValue("GSpd")
	if GSpdraw < 300 then GSpd = GSpdraw end

	local GAltraw = getValue("GAlt")
	if GAltraw < 10000 then GAlt = GAltraw end

	if getValue("Sats") > 0
	then
		Satsraw = getValue("Sats")
	else
		if SatsSensor == -1 then
			SatsSensor = getSourceIndex(CHAR_TELEMETRY.."5100")
		else
			if SatsSensor ~= nil then Satsraw = getValue(SatsSensor) end
		end
	end
	if Satsraw < 10000 then Sats = Satsraw end

	if getValue("PDOP") > 0
	then
		PDOPraw = getValue("PDOP")
	else
		if PDOPSensor == -1 then
			PDOPSensor = getSourceIndex(CHAR_TELEMETRY.."5101")
		else
			if PDOPSensor ~= nil then PDOPraw = getValue(PDOPSensor) end
		end
	end
	if PDOPraw < 10000 then PDOP = PDOPraw end

	trackswitchcondition = lib.getTrackSwitchCondition()

end



	-- GPS Daten ermitteln und DisG und DisM berechnen ========================================
	-- <BEGIN> ================================================================================
local gpsValuelat1 = "no Data"
local gpsValuelon1 = "no Data"
local gpsValuelat2 = "no Data"
local gpsValuelon2 = "no Data"
local gpsValuelat3 = "no Data"
local gpsValuelon3 = "no Data"

local timestampgps

local function rnd(v,d)
	if d then
		return math.floor((v*10^d)+0.5)/(10^d)
	else
		return math.floor(v+0.5)
	end
end

local function getTelemetryId(name)
	local field = getFieldInfo(name)
	if field then
		return field.id
	else
		return -1
	end
end

local function GetGPSData(wgt)
	local newtimegps = math.floor(getTime()/100)
	if newtimegps ~= timestampgps then
		timestampgps = newtimegps

		local gpsId = getTelemetryId("GPS")
		local gpsLatLon = getValue(gpsId)
		if (type(gpsLatLon) == "table") then
			gpsValuelat2 = rnd(gpsLatLon["lat"],6)
			gpsValuelon2 = rnd(gpsLatLon["lon"],6)
			if gpsValuelat1 == "no Data" or gpsValuelat1 == 0 then
				gpsValuelat1 = rnd(gpsLatLon["lat"],6)
			end
			if gpsValuelon1 == "no Data" or gpsValuelon1 == 0 then
				gpsValuelon1 = rnd(gpsLatLon["lon"],6)
			end
			if trackswitchcondition then
				if (gpsValuelat3 == "no Data" or gpsValuelat3 == 0) then
					gpsValuelat3 = rnd(gpsLatLon["lat"],6)
				end
				if (gpsValuelon3 == "no Data" or gpsValuelon3 == 0) then
					gpsValuelon3 = rnd(gpsLatLon["lon"],6)
				end
			end
		end
	end
end

-- Entfernung zweier GPS-Positionen in Metern (Näherung für kurze Strecken)
local function distance(lat1, lon1, lat2, lon2)
	local lat = math.cos((lat1 + lat2) / 2 * 0.01745)
	local dx = math.abs(111.3 * lat * (lon1 - lon2))
	local dy = math.abs(111.3 * (lat1 - lat2))
	return math.sqrt(dx*dx + dy*dy) * 1000
end

local function calcDisG(lat1, lon1, lat2, lon2)
	if lat1 ~= "no Data" and lon1 ~= "no Data" and lat2 ~= "no Data" and lon2 ~= "no Data" then
		return distance(lat1, lon1, lat2, lon2)
	else
		return 0
	end
end

local function calcDisM(a,b)
	if a ~= 0 or b ~= 0 then
		return math.sqrt((a*a) + (b*b))
	else
		return 0
	end
end

	-- GPS Daten ermitteln und DisG und DisM berechnen ========================================
	-- <END> ==================================================================================

local function resetvalues(wgt)
	local ModelRxIDNachher = lib.getRxID()
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			gpsValuelat1 = "no Data"
			gpsValuelon1 = "no Data"
			gpsValuelat2 = "no Data"
			gpsValuelon2 = "no Data"
			gpsValuelat3 = "no Data"
			gpsValuelon3 = "no Data"
			GSpdmaxsave = 0
			GAltmaxsave = 0
			GAltOffsetdone = 0
			GAl2 = 0
			GAl2maxsave = 0
			DisMmaxsave = 0
			DisGmaxsave = 0
			gpsfixmessagedone = 0
			Track = 0
			Sats = 0
			Satssave = 0
			SatsSeen = 0
			PDOP = 0
			PDOPsave = 0
			PDOPSeen = 0
			SatsSensor = -1
			PDOPSensor = -1
		end
	end
	ModelRxIDVorher = ModelRxIDNachher
end

local function savevalues(wgt)
	local newtimerefresh = math.floor(getTime()/100)

	if newtimerefresh ~= timestamprefresh then
		timestamprefresh = newtimerefresh
		getSensors(wgt)

		if GSpd > GSpdmaxsave then
			GSpdmaxsave = GSpd
		end

		if Sats > 0 then
			if Sats == 100 or Sats >= 200 then
				Satssave = Sats *0.01
			else
				if Sats >100 then
					Satssave = Sats - 100
				else
					Satssave = Sats
				end
			end
			SatsSeen = 1
		end

		if PDOP > 0 then
			PDOPsave = PDOP *0.01
			PDOPSeen = 1
		end

		if GAlt > GAltmaxsave then
			GAltmaxsave = GAlt
		else
			if GAltmaxsave == 0 then
				nodataGAlt = 1
			end
		end

		if GAltOffsetdone == 0 and GAlt > 0 then
			GAltOffset = GAlt
			GAltOffsetdone = 1
			nodataGAlt = 0
		end

		if GAltOffsetdone == 1 and RSSI > 0 then
			GAl2 = GAlt - GAltOffset
		end
		if RSSI == 0 then
			GAl2 = 0
			DisG = 0
			DisM = 0
			nodataGAlt = 1
			GAltOffsetdone = 0
		end

		if GAl2 > GAl2maxsave and GAl2 < 10000 then
			GAl2maxsave = GAl2
		end

		local disg = calcDisG(gpsValuelat1,gpsValuelon1,gpsValuelat2,gpsValuelon2)
		if disg < 10000 then
			DisG = rnd(disg,0)
			if DisG > DisGmaxsave then
				DisGmaxsave = DisG
			end
		end
		local dism = calcDisM(DisG,GAl2)
		if dism < 10000	then
			DisM = rnd(dism, 0)
			if DisM > DisMmaxsave then
				DisMmaxsave = DisM
			end
		end

		if trackswitchcondition then
			if gpsValuelat2 ~= "no Data" and gpsValuelon2 ~= "no Data" and gpsValuelat3 ~= "no Data" and gpsValuelon3 ~= "no Data" then
				-- print("Track vorher: " .. Track)
				local Tracknew = distance(gpsValuelat3, gpsValuelon3, gpsValuelat2, gpsValuelon2)
				if Tracknew < 1000 then
					Track = Track + Tracknew
				end
				gpsValuelat3 = gpsValuelat2
				gpsValuelon3 = gpsValuelon2
				-- print("Track nachher: " .. Track)
			end
		else
			gpsValuelat3 = "no Data"
			gpsValuelon3 = "no Data"
		end
		if not trackswitchcondition and RK02readysaved == 1 then
			local file, err = io.open(filename, "a")
			if file then
				io.write(file, "GSpdmax (km/h)         : " .. round(GSpdmaxsave,0) .. "\nGAltmax NN (m)         : " .. round(GAltmaxsave,0) .. "\nGAltmax Grund (m)      : " .. round(GAl2maxsave,0) .. "\nDistanz Grund (m)      : " .. round(DisGmaxsave,0) .. "\nDistanz Modell (m)     : " .. round(DisMmaxsave,0) .. "\nStart Position         : " .. gpsValuelat1 .. ", " .. gpsValuelon1 .. "\nModell Position        : " .. gpsValuelat2 .. ", " .. gpsValuelon2 .. "\ngeflogene Strecke (m)  : " .. round(Track,0) .. "\nAnzahl Satelliten      : " .. round(Satssave,0) .. "\nPDOP (ideal <2.00)     : " .. round(PDOPsave,2) .. "\n")
				io.close(file)
				RK01readysaved = 0
				RK02readysaved = 0
				RK03readysaved = 1
				-- print("Datei erfolgreich gespeichert: " .. filename)
			else
				print("Fehler beim Öffnen der Datei: " .. tostring(err))
			end
		end
	end
end

local function gpsfixmessage(wgt)
	if GAltmaxsave > 0 and gpsfixmessagedone == 0 then
		gpsfixmessagedone = 1
		playFile("gpsfix.wav") -- GPS Fix erfolgreich
	end

end
------------------------------------------------------------

-- This size is for top bar wgts
local function refreshZoneTiny(wgt) lib.drawNurVollbild(wgt) end

--- Size is 160x32 1/8th
local function refreshZoneSmall(wgt) lib.drawNurVollbild(wgt) end

--- Size is 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt) lib.drawNurVollbild(wgt) end

--- Size is 192x152 1/2
local function refreshZoneLarge(wgt) lib.drawNurVollbild(wgt) end

-- Rechte Spalte: Label und GPS-Position (lat über lon) rechtsbündig bei x+390
local function drawPosition(wgt, y, label, nodata, leer, lat, lon)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+200, wgt.zone.y+y, label, SMLSIZE + CUSTOM_COLOR)

	if nodata == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if leer then
		lcd.drawText(wgt.zone.x+390, wgt.zone.y+y, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+390, wgt.zone.y+y+15, "- - ", CUSTOM_COLOR + RIGHT)
	else
		lcd.drawText(wgt.zone.x+390, wgt.zone.y+y, lat, SMLSIZE + CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+390, wgt.zone.y+y+15, lon, SMLSIZE + CUSTOM_COLOR + RIGHT)
	end
end


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
	lib.drawHeader(wgt, "RK03", RKWidgetVersion, ModelRxIDVorher)
	--lcd.drawLine(45, 72, 435, 72, 255, 0)

	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)

	-- "- - " in der linken Spalte, solange es keinen GPS-Fix gab
	local keinFix = (GAltmaxsave == 0)

	-- 1. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 030, "GSpd (km/h)", nodataGAlt, GSpd, GSpdmaxsave, 0, keinFix)

	-- 1. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	drawPosition(wgt, 030, "Start-Position", nodataGAlt, gpsValuelat1 == "no Data", gpsValuelat1, gpsValuelon1)

	-- 2. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 060, "GAlt NN (m)", nodataGAlt, GAlt, GAltmaxsave, 0, keinFix)

	-- 2. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	drawPosition(wgt, 060, "Modell-Position", nodataGAlt, gpsValuelat1 == "no Data", gpsValuelat2, gpsValuelon2)

	-- 3. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 090, "GAlt Gnd (m)", nodataGAlt, GAl2, GAl2maxsave, 0, keinFix)

	-- 3. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawValue(wgt, 090, "geflogene Strecke (m)", nodataGAlt, keinFix, Track, 0)
	-- lcd.drawText(wgt.zone.x+376, wgt.zone.y+093, "m", SMLSIZE + CUSTOM_COLOR)

	-- 4. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 120, "Dist Gnd (m)", nodataGAlt, DisG, DisGmaxsave, 0, keinFix)

	-- 4. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawValue(wgt, 120, "Satelliten", nodataGAlt, SatsSeen ~= 1, Satssave, 0)

	-- 5. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 150, "Dist Mod (m)", nodataGAlt, DisM, DisMmaxsave, 0, keinFix)

	-- 5. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawValue(wgt, 150, "PDOP (ideal <2.00)", nodataGAlt, PDOPSeen ~= 1, PDOPsave, 2)

	-- ===============================================================================================
	-- ===============================================================================================

end

local function refresh(wgt)

	if (wgt==nil) then
		print("refresh(nil)")
		return
	end

	if (wgt.options==nil) then
		print("refresh(wgt.options=nil)")
		return
	end

	if libfehler ~= nil then
		drawLibFehler(wgt)
		return
	end

	-- MinMax Werte im Vordergrund sichern ===========================================================
	-- ===============================================================================================
	savevalues(wgt)

	-- RESET nach "LS61" oder Modellwechsel eigener Screen ============================================
	-- ===============================================================================================
	resetvalues(wgt)

	-- GPS Daten im Vordergrund ermitteln ============================================================
	-- ===============================================================================================
	GetGPSData(wgt)

	-- GPS Fix Soundmessage ==========================================================================
	-- ===============================================================================================
	gpsfixmessage(wgt)

	if     wgt.zone.w  > 380 and wgt.zone.h > 165 then refreshZoneXLarge(wgt)
	elseif wgt.zone.w  > 180 and wgt.zone.h > 145 then refreshZoneLarge(wgt)
	elseif wgt.zone.w  > 170 and wgt.zone.h >  65 then refreshZoneMedium(wgt)
	elseif wgt.zone.w  > 150 and wgt.zone.h >  28 then refreshZoneSmall(wgt)
	elseif wgt.zone.w  >  65 and wgt.zone.h >  35 then refreshZoneTiny(wgt)
	end
end

local function background(wgt)
	if libfehler ~= nil then return end

	-- MinMax Werte im Hintergrund speichern =========================================================
	-- ===============================================================================================
	savevalues(wgt)

	-- RESET nach "LS61" wenn im Hintergrund ==========================================================
	-- ===============================================================================================
	resetvalues(wgt)

	-- GPS Daten im Hintergrund ermitteln ============================================================
	-- ===============================================================================================
	GetGPSData(wgt)

	-- GPS Fix Soundmessage ==========================================================================
	-- ===============================================================================================
	gpsfixmessage(wgt)
end

return { name="RK03", options=options, create=create, update=update, refresh=refresh, background=background}
