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
if libfehler ~= nil then print("RK04: " .. libfehler) end
local printTable, round
if libfehler == nil then
	printTable = lib.printTable
	round = lib.round
end

-- Hinweis statt der Werte, wenn die RK-Lib fehlt oder nicht passt
local function drawLibFehler(wgt)
	lcd.setColor(CUSTOM_COLOR, RED)
	if wgt.zone.w > 380 then
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK04: " .. libfehler, SMLSIZE + CUSTOM_COLOR)
	else
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK-Lib Fehler", SMLSIZE + CUSTOM_COLOR)
	end
end

local options = {
	{ "TextColor", COLOR, WHITE },
	{ "NoDataColor", COLOR, BLACK },
	{ "RSSIWarning", BOOL, 1},
	{ "ShowVFR", BOOL, 0},
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

-- Anzeigenamen: RSSI/VFR, bei ELRS RQly/TQly
local rssilabel
local vfrlabel

local nodataRSSI =1
local RSSI = 0
local RSSImin = 0
local RSSIminsave = 0

local nodataVFR = 1
local VFR = 0
local VFRmin = 0
local VFRminsave = 0

local ModelRxIDVorher = -1

local RSSIlow_warn = 0
local RSSIlow_crit = 0
local lasttime_rssi_warn = 0
local lasttime_rssi_crit = 0
local startRSSIdelaywarn
local startRSSIdelaycrit

local timestamprefresh = 0

local logsaved = 0
local function getFormattedDateTime()
	local now = getDateTime()

	-- Datum im Format YYYY-MM-DD
	local formattedDate = string.format("%04d-%02d-%02d", now.year, now.mon, now.day)
	-- Zeit im Format HH-MM-SS
	-- local formattedTime = string.format("%02d-%02d-%02d", now.hour, now.min, now.sec)
	local formattedTime = string.format("%02d%02d%02d", now.hour, now.min, now.sec)

	return formattedDate, formattedTime
end

local function getSensors(wgt)
	if getValue("RQly-") > 0 then
		RSSI = getValue("RQly")
		RSSImin = getValue("RQly-")
		rssilabel="RQly"
	else
		RSSI = getValue("RSSI")
		RSSImin = getValue("RSSI-")
		-- einmal erkanntes RQly bleibt bis zum Reset stehen
		if rssilabel ~= "RQly" then
			rssilabel="RSSI"
		end
	end

	if getValue("TQly-") > 0 then
		VFR = getValue("TQly")
		VFRmin = getValue("TQly-")
		vfrlabel="TQly"
	else
		VFR = getValue("VFR")
		VFRmin = getValue("VFR-")
		-- einmal erkanntes TQly bleibt bis zum Reset stehen
		if vfrlabel ~= "TQly" then
			vfrlabel="VFR "
		end
	end
end

local function rssiwarning(wgt)
	if wgt.options.RSSIWarning ~= 0 then
		-- print ("RSSIWarning activ: " .. wgt.options.RSSIWarning)

		if RSSI > 0 and RSSI < 35 then
			if RSSI > 0 and RSSI < 32 then
				if RSSIlow_crit == 0 then
					startRSSIdelaycrit = getTime()
					RSSIlow_crit = 1
				end
				if (getTime() - startRSSIdelaycrit) >= 100 then
					local timenow_rssi_crit = getTime()
					if (timenow_rssi_crit - lasttime_rssi_crit) >= 500 then
						lasttime_rssi_crit = timenow_rssi_crit
						-- print ("RSSI < 32: " .. RSSI)
						playFile("system/rssi_red.wav")
					end
				end
			else
				if RSSIlow_warn == 0 then
					startRSSIdelaywarn = getTime()
					RSSIlow_warn = 1
				end
				if (getTime() - startRSSIdelaywarn) >= 100 then
					local timenow_rssi_warn = getTime()
					if (timenow_rssi_warn - lasttime_rssi_warn) >= 1000 then
						lasttime_rssi_warn = timenow_rssi_warn
						-- print ("RSSI < 35: " .. RSSI .. " " .. lasttime_rssi_warn)
						playFile("system/rssi_org.wav")
					end
				end
			end

		else
			RSSIlow_warn = 0
			lasttime_rssi_warn = 0
			if RSSI == 0 then RSSIlow_crit = 0 end
			lasttime_rssi_crit = 0
		end
	end
end

local function resetvalues(wgt)
	local ModelRxIDNachher = lib.getRxID()
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			RSSIminsave = 0
			VFRminsave = 0
			rssilabel="RSSI"
			vfrlabel="VFR "
		end
	end
	ModelRxIDVorher = ModelRxIDNachher
end

local function savevalues(wgt)
	local newtimerefresh = math.floor(getTime()/100)
	if newtimerefresh ~= timestamprefresh then
		-- print("timestamprefresh: " .. timestamprefresh)
		-- print("newtimerefresh: " .. newtimerefresh)
		-- print("------------------------")
		timestamprefresh = newtimerefresh
		getSensors(wgt)

		if RSSImin ~= 0 then
			RSSIminsave = RSSImin
			nodataRSSI = 0
		else
			nodataRSSI = 1
		end
		if VFRmin ~= 0 then
			VFRminsave = VFRmin
			nodataVFR = 0
		else
			nodataVFR = 1
		end

		-- Motorschutzschalter selbst auswerten, damit das Log auch ohne RK01/RK03/RK05 angelegt wird
		trackswitchcondition = lib.getTrackSwitchCondition()
		if trackswitchcondition then logsaved = logsaved +1 end
		-- print("logsaved "..logsaved)
		if not trackswitchcondition and logsaved < 30 then logsaved=0 end
		if not trackswitchcondition and logsaved >= 30 then
			logsaved=0
			local modelInfo = model.getInfo()
			local namemodel = modelInfo.name
			local namefile = modelInfo.filename
			-- print("Name vom Modell: " .. namemodel)
			-- print("Name von Datei: " .. namefile)
			local date, time = getFormattedDateTime()
			filename = string.format("/LOGS/%s-%s-%s_RK-Widget.txt", namemodel, date, time)
			local file, err = io.open(filename, "w")
			if file then
				io.write(file, "Modell                 : " .. namemodel .. "\nDateiname              : " .. namefile .. "\n"..rssilabel.."min                : " .. round(RSSIminsave,0) .. "\n"..vfrlabel.."min                : " .. round(VFRminsave,0) .. "\n")
				io.close(file)
				RK04readysaved = 1
				-- print("Datei erfolgreich gespeichert: " .. filename)
			else
				print("Fehler beim Öffnen der Datei: " .. tostring(err))
			end
		end
	end
end
------------------------------------------------------------

-- This size is for top bar wgts
local function refreshZoneTiny(wgt)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)

	if nodataRSSI == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if wgt.options.ShowVFR ~= 1 then
		lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-00, rssilabel.."  "..round(RSSI,0), CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+16, rssilabel.."- "..round(RSSIminsave,0), CUSTOM_COLOR)
	end

	if nodataVFR == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	-- print("ShowVFR"..wgt.options.ShowVFR)
	if wgt.options.ShowVFR == 1 then
		lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-00, vfrlabel.."  "..round(VFR,0), CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+16, vfrlabel.."- "..round(VFRminsave,0), CUSTOM_COLOR)
	end
end

--- Size is 160x32 1/8th
local function refreshZoneSmall(wgt) lib.drawNurVollbild(wgt) end

--- Size is 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt) lib.drawNurVollbild(wgt) end

--- Size is 192x152 1/2
local function refreshZoneLarge(wgt) lib.drawNurVollbild(wgt) end


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
	lib.drawHeader(wgt, "RK04", RKWidgetVersion, ModelRxIDVorher)
	--lcd.drawLine(45, 72, 435, 72, 255, 0)

	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	-- 1. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+005, wgt.zone.y+20, rssilabel, CUSTOM_COLOR)

	if nodataRSSI == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if RSSIminsave == 0 then
		lcd.drawText(wgt.zone.x+100, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+155, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
	else
		lcd.drawText(wgt.zone.x+100, wgt.zone.y+20, round(RSSI,0), CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+155, wgt.zone.y+20, round(RSSIminsave,0), CUSTOM_COLOR + RIGHT)
	end
	lcd.drawText(wgt.zone.x+101, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+156, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+156, wgt.zone.y+27, "min", SMLSIZE + CUSTOM_COLOR)

	-- 1. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+200, wgt.zone.y+20, vfrlabel, CUSTOM_COLOR)

	if nodataVFR == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if VFRminsave == 0 then
		lcd.drawText(wgt.zone.x+290, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+355, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
	else
		lcd.drawText(wgt.zone.x+290, wgt.zone.y+20, round(VFR,0), CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+355, wgt.zone.y+20, round(VFRminsave,0), CUSTOM_COLOR + RIGHT)
	end
	lcd.drawText(wgt.zone.x+291, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+356, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+356, wgt.zone.y+27, "min", SMLSIZE + CUSTOM_COLOR)

	-- 2. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 000, 050, "Label", nodataX, X, Xmaxsave, 0)

	-- 2. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 050, "Label", nodataX, X, Xmaxsave, 0)

	-- 3. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 000, 080, "Label", nodataX, X, Xmaxsave, 0)

	-- 3. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 080, "Label", nodataX, X, Xmaxsave, 0)

	-- 4. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 000, 110, "Label", nodataX, X, Xmaxsave, 0)

	-- 4. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 110, "Label", nodataX, X, Xmaxsave, 0)

	-- 5. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 000, 140, "Label", nodataX, X, Xmaxsave, 0)

	-- 5. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 140, "Label", nodataX, X, Xmaxsave, 0)

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

	-- RSSI Warnung ==================================================================================
	-- ===============================================================================================
	rssiwarning(wgt)

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

	-- RSSI Warnung ==================================================================================
	-- ===============================================================================================
	rssiwarning(wgt)
end

return { name="RK04", options=options, create=create, update=update, refresh=refresh, background=background}
