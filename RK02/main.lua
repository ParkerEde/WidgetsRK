local RKWidgetVersion = "1.1.10"
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
if libfehler ~= nil then print("RK02: " .. libfehler) end
local printTable, round
if libfehler == nil then
	printTable = lib.printTable
	round = lib.round
end

-- Hinweis statt der Werte, wenn die RK-Lib fehlt oder nicht passt
local function drawLibFehler(wgt)
	lcd.setColor(CUSTOM_COLOR, RED)
	if wgt.zone.w > 380 then
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK02: " .. libfehler, SMLSIZE + CUSTOM_COLOR)
	else
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK-Lib Fehler", SMLSIZE + CUSTOM_COLOR)
	end
end

local options = {
	{ "TextColor", COLOR, WHITE },
	{ "NoDataColor", COLOR, BLACK },
	{ "VoiceRepeatTime", VALUE, 30, 1, 120}
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

local nodataAlt =1
local Alt = 0
local Altmax = 0
local Altmaxsave = 0

local VSpd = 0
local VSpdmaxsave = 0
local VSpdminsave = 0

local ModelRxIDVorher = -1
local lasttime_sc = 0
local voicecycletime

local timestamprefresh = 0

local function mskmh(nummskmh)
	return (nummskmh * 3.6)
end

local function getSensors(wgt)
	local Altraw = getValue("Alt")
	if Altraw < 1000 then Alt = Altraw end
	Altmax = getValue("Alt+")
	local VSpdraw = getValue("VSpd")
	if VSpdraw > -1000 and VSpdraw < 1000 then VSpd = VSpdraw end
end

local function voiceoutput(wgt)
	local voiceoutput_sc_switch = getValue(voiceoutputswitch_1)
	local timenow_sc = getTime() + 10000
	-- print ("gettimeSC:" .. timenow_sc)
	if wgt.options.VoiceRepeatTime ~= nil then
		voicecycletime = (wgt.options.VoiceRepeatTime * 100)
		-- print ("voicecycletime RK02: " .. voicecycletime)
	end
	if voiceoutput_sc_switch == 0 then
		lasttime_sc = 0
	end
	if ((timenow_sc - lasttime_sc) >= voicecycletime) then
		if voiceoutput_sc_switch == -1024 then --SC oben
			lasttime_sc = timenow_sc
			if nodataAlt == 1 then
				playFile("nodata.wav")
			else
				playNumber(Alt, 9)
			end
		end
	end
end

local function resetvalues(wgt)
	local ModelRxIDNachher = lib.getRxID()
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			Altmaxsave = 0
			VSpdmaxsave = 0
			VSpdminsave = 0
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
		if Altmax ~= 0 then
			if Alt > Altmaxsave then Altmaxsave = Alt end
			nodataAlt = 0
		else
			nodataAlt = 1
		end

		if VSpd > 0 then
			if VSpd > VSpdmaxsave then VSpdmaxsave = VSpd end
		end

		if VSpd < 0 then
			if VSpd < VSpdminsave then VSpdminsave = VSpd end
		end

		if not trackswitchcondition and RK01readysaved == 1 then
			local file, err = io.open(filename, "a")
			if file then
				io.write(file, "Altmax (m)             : " .. round(Altmaxsave,0) .. "\nVSpdmax (m/s)          : " .. round(VSpdmaxsave,0) .. "   	km/h:  " .. round(mskmh(VSpdmaxsave),0) .. "\nVSpdmin (m/s)          :" .. round(VSpdminsave,0) .. "   	km/h: " .. round(mskmh(VSpdminsave),0) .. "\n")
				io.close(file)
				RK01readysaved = 0
				RK02readysaved = 1
				-- print("Datei erfolgreich gespeichert: " .. filename)
			else
				print("Fehler beim Öffnen der Datei: " .. tostring(err))
			end
		end
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

-- Wertezeile mit drei Werten: aktuell auf Höhe y, min 8 Pixel darüber, max 8 Pixel darunter
local function drawRowMinMax(wgt, x, y, label, nodata, saved, current, min, max)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+x, wgt.zone.y+y, label, SMLSIZE + CUSTOM_COLOR)

	if nodata == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if saved == 0 then
		lcd.drawText(wgt.zone.x+x+130, wgt.zone.y+y, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y-8, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y+8, "- - ", CUSTOM_COLOR + RIGHT)
	else
		lcd.drawText(wgt.zone.x+x+130, wgt.zone.y+y, round(current,0), CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y-8, round(min,0), CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y+8, round(max,0), CUSTOM_COLOR + RIGHT)
	end
end


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
	lib.drawHeader(wgt, "RK02", RKWidgetVersion, ModelRxIDVorher)
	--lcd.drawLine(45, 72, 435, 72, 255, 0)

	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+340, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+270, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)

	-- 1. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	lib.drawRow(wgt, 000, 030, "Alt (m)", nodataAlt, Alt, Altmaxsave, 0)

	-- 1. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 030, "Label", nodataX, X, Xmaxsave, 0)

	-- 2. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	drawRowMinMax(wgt, 000, 060+15, "VSpd (m/s)", nodataAlt, Altmaxsave, VSpd, VSpdminsave, VSpdmaxsave)

	-- 2. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 060, "Label", nodataX, X, Xmaxsave, 0)

	-- 3. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- drawRowMinMax(wgt, 000, 090, "Label", nodataX, Xmaxsave, X, Xminsave, Xmaxsave)

	-- 3. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 090, "Label", nodataX, X, Xmaxsave, 0)

	-- 4. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	drawRowMinMax(wgt, 000, 120, "VSpd (km/h)", nodataAlt, Altmaxsave, mskmh(VSpd), mskmh(VSpdminsave), mskmh(VSpdmaxsave))

	-- 4. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 120, "Label", nodataX, X, Xmaxsave, 0)

	-- 5. SENSOR Zeile 1.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 000, 150, "Label", nodataX, X, Xmaxsave, 0)

	-- 5. SENSOR Zeile 2.Spalte ======================================================================
	-- ===============================================================================================
	-- lib.drawRow(wgt, 200, 150, "Label", nodataX, X, Xmaxsave, 0)

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

	-- Sprachausgabe Werte ===========================================================================
	-- ===============================================================================================
	voiceoutput(wgt)

	-- 1. Zeile Modellname , Rx ID ===================================================================
	-- ===============================================================================================

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

	-- Sprachausgabe Werte ===========================================================================
	-- ===============================================================================================
	voiceoutput(wgt)
end

return { name="RK02", options=options, create=create, update=update, refresh=refresh, background=background}
