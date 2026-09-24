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
if libfehler ~= nil then print("RK05: " .. libfehler) end
local printTable, round
if libfehler == nil then
	printTable = lib.printTable
	round = lib.round
end

-- Hinweis statt der Werte, wenn die RK-Lib fehlt oder nicht passt
local function drawLibFehler(wgt)
	lcd.setColor(CUSTOM_COLOR, RED)
	if wgt.zone.w > 380 then
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK05: " .. libfehler, SMLSIZE + CUSTOM_COLOR)
	else
		lcd.drawText(wgt.zone.x, wgt.zone.y, "RK-Lib Fehler", SMLSIZE + CUSTOM_COLOR)
	end
end

local options = {
	{ "TextColor", COLOR, WHITE },
	{ "NoDataColor", COLOR, BLACK }
}

local function update(wgt, options )
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

local nodataCels1 = 1
local Pack1 = 0
local Pack1minsave = 0
local Pack1Zelle = {0, 0, 0, 0, 0, 0}
local Pack1ZelleMinSave = {0, 0, 0, 0, 0, 0}

local nodataCels2 = 1
local Pack2 = 0
local Pack2minsave = 0
local Pack2Zelle = {0, 0, 0, 0, 0, 0}
local Pack2ZelleMinSave = {0, 0, 0, 0, 0, 0}

local ModelRxIDVorher = -1

local timestamprefresh = 0

-- Liest einen Zellensensor (Cels/Cel2) in die Tabelle zellen.
-- Rückgabe: neuer nodata-Wert. Liefert der Sensor nil, bleibt nodata unverändert.
local function readCells(sensor, zellen, nodata)
	local cellstable = getValue(sensor)
	-- print("===============" .. sensor .. "================")
	-- printTable (cellstable)
	if cellstable ~= nil then
		if type(cellstable) == "table" then
			nodata = 0
			for i = 1, 6 do
				if cellstable[i] ~= nil then
					local rawValue = cellstable[i]
					-- print ("Zelle " .. i .. ": " .. rawValue)
					if rawValue < 1000 then
						zellen[i] = rawValue
					end
				end
			end
		else
			nodata = 1
		end
	end
	-- printTable(zellen)
	return nodata
end

local function getSensors(wgt)
	nodataCels1 = readCells("Cels", Pack1Zelle, nodataCels1)
	nodataCels2 = readCells("Cel2", Pack2Zelle, nodataCels2)
end

-- Merkt sich pro Zelle den kleinsten Wert
local function saveMin(zellen, minSave)
	for i = 1, #zellen do
		if zellen[i] ~= 0 then
			if zellen[i] < minSave[i] then
				minSave[i] = zellen[i]
			end
			if minSave[i] < 2.1 then
				minSave[i] = zellen[i]
			end
		end
	end
end

local function sumCells(zellen)
	return zellen[1] + zellen[2] + zellen[3] + zellen[4] + zellen[5] + zellen[6]
end

local function resetvalues(wgt)
	local ModelRxIDNachher = lib.getRxID()
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			Pack1Zelle = {0, 0, 0, 0, 0, 0}
			Pack1ZelleMinSave = {0, 0, 0, 0, 0, 0}

			Pack2Zelle = {0, 0, 0, 0, 0, 0}
			Pack2ZelleMinSave = {0, 0, 0, 0, 0, 0}
		end
	end
	ModelRxIDVorher = ModelRxIDNachher
end

local function savevalues(wgt)
	-- getSensors(wgt)
	trackswitchcondition = lib.getTrackSwitchCondition()
	local newtimerefresh = math.floor(getTime()/100)
	if newtimerefresh ~= timestamprefresh then
		-- print("timestamprefresh: " .. timestamprefresh)
		-- print("newtimerefresh: " .. newtimerefresh)
		-- print("------------------------")
		timestamprefresh = newtimerefresh
		getSensors(wgt)

		saveMin(Pack1Zelle, Pack1ZelleMinSave)
		saveMin(Pack2Zelle, Pack2ZelleMinSave)

		Pack1 = sumCells(Pack1Zelle)
		Pack1minsave = sumCells(Pack1ZelleMinSave)
		-- print("Pack1: " .. Pack1)
		-- print("Pack1minsave: " .. Pack1minsave)
		Pack2 = sumCells(Pack2Zelle)
		Pack2minsave = sumCells(Pack2ZelleMinSave)
		-- print("Pack2: " .. Pack2)
		-- print("Pack2minsave: " .. Pack2minsave)

		if not trackswitchcondition and RK03readysaved == 1 then
			local file, err = io.open(filename, "a")
			if file then
				io.write(file, "Pack 1 min(V)          : " .. round(Pack1,2) .. "\n  Pack1 Zelle1 min(V)  : " .. round(Pack1ZelleMinSave[1],2) .. "\n  Pack1 Zelle2 min(V)  : " .. round(Pack1ZelleMinSave[2],2) .. "\n  Pack1 Zelle3 min(V)  : " .. round(Pack1ZelleMinSave[3],2) .. "\n  Pack1 Zelle4 min(V)  : " .. round(Pack1ZelleMinSave[4],2) .. "\n  Pack1 Zelle5 min(V)  : " .. round(Pack1ZelleMinSave[5],2) .. "\n  Pack1 Zelle6 min(V)  : " .. round(Pack1ZelleMinSave[6],2) .. "\n")
				io.write(file, "Pack 2 min(V)          : " .. round(Pack2,2) .. "\n  Pack2 Zelle1 min(V)  : " .. round(Pack2ZelleMinSave[1],2) .. "\n  Pack2 Zelle2 min(V)  : " .. round(Pack2ZelleMinSave[2],2) .. "\n  Pack2 Zelle3 min(V)  : " .. round(Pack2ZelleMinSave[3],2) .. "\n  Pack2 Zelle4 min(V)  : " .. round(Pack2ZelleMinSave[4],2) .. "\n  Pack2 Zelle5 min(V)  : " .. round(Pack2ZelleMinSave[5],2) .. "\n  Pack2 Zelle6 min(V)  : " .. round(Pack2ZelleMinSave[6],2) .. "\n")
				io.close(file)
				RK01readysaved = 0
				RK02readysaved = 0
				RK03readysaved = 0
				RK04readysaved = 0
				RK05readysaved = 1
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


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
	lib.drawHeader(wgt, "RK05", RKWidgetVersion, ModelRxIDVorher)
	--lcd.drawLine(45, 72, 435, 72, 255, 0)

	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "minimum", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+340, wgt.zone.y+016, "minimum", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+270, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)

	-- 1. Zeile: Packspannung, linke Spalte Pack 1, rechte Spalte Pack 2 ============================
	lib.drawRow(wgt, 000, 030, "Pack 1 (V)", nodataCels1, Pack1, Pack1minsave, 2)
	lib.drawRow(wgt, 200, 030, "Pack 2 (V)", nodataCels2, Pack2, Pack2minsave, 2)

	-- 2.-7. Zeile: Zelle 1 bis 6 ===================================================================
	for i = 1, 6 do
		local y = 030 + i * 20
		local label = string.format("Zelle %02d (V)", i)
		lib.drawRow(wgt, 000, y, label, nodataCels1, Pack1Zelle[i], Pack1ZelleMinSave[i], 2)
		lib.drawRow(wgt, 200, y, label, nodataCels2, Pack2Zelle[i], Pack2ZelleMinSave[i], 2)
	end
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
end

return { name="RK05", options=options, create=create, update=update, refresh=refresh, background=background}
