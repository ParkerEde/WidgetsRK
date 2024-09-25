local RKWidgetVersion = "1.1.05"
-- +++++++++++ KONFIGURATIONSTEIL Anfang +++++++++++ 
settings,err = loadScript ("/WIDGETS/RK-Settings/RK-Settings.lua")

if (settings ~= nil) then
     settings()
  else
     print(err)
  end
-- +++++++++++ KONFIGURATIONSTEIL Ende +++++++++++ 
local function printTable( t )
 
    local printTable_cache = {}
 
    local function sub_printTable( t, indent )
 
        if ( printTable_cache[tostring(t)] ) then
            print( indent .. "*" .. tostring(t) )
        else
            printTable_cache[tostring(t)] = true
            if ( type( t ) == "table" ) then
                for pos,val in pairs( t ) do
                    if ( type(val) == "table" ) then
                        print( indent .. "[" .. pos .. "] => " .. tostring( t ).. " {" )
                        sub_printTable( val, indent .. string.rep( " ", string.len(pos)+8 ) )
                        print( indent .. string.rep( " ", string.len(pos)+6 ) .. "}" )
                    elseif ( type(val) == "string" ) then
                        print( indent .. "[" .. pos .. '] => "' .. val .. '"' )
                    else
                        print( indent .. "[" .. pos .. "] => " .. tostring(val) )
                    end
                end
            else
                print( indent..tostring(t) )
            end
        end
    end
 
    if ( type(t) == "table" ) then
        print( tostring(t) .. " {" )
        sub_printTable( t, "  " )
        print( "}" )
    else
        sub_printTable( t, "  " )
    end
end

local options = {

  { "TextColor", COLOR, WHITE },
  { "NoDataColor", COLOR, BLACK },
  { "RSSIWarning", BOOL, 1},
  { "ShowVFR", BOOL, 0}
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



local nodataRSSI =1
local RSSI = 0
local RSSImin = 0
local RSSIminsave = 0

local nodataVFR = 1
local VFR = 0
local VFRmin = 0
local VFRminsave = 0

local ModelRxID = -1
local ModelRxID2 = -1
local ModelRxIDVorher = -1
local ModelRxIDNachher = -1
local Modelname = 0

local RSSIlow_warn = 0
local RSSIlow_crit = 0
local lasttime_rssi_warn = 0
local lasttime_rssi_crit = 0

local timestamprefresh = 0

local function round(num, decimal)
	if     decimal == 0 then return (string.format("%.0f", num))
	elseif decimal == 1 then return (string.format("%.1f", num))
	elseif decimal == 2 then return (string.format("%.2f", num))
	end
end

local logsaved = 0
local function getFormattedDateTime()
    local year = getDateTime().year
    local mon = getDateTime().mon
    local day = getDateTime().day
    local hour = getDateTime().hour
    local min = getDateTime().min
    local sec = getDateTime().sec
    
    -- Datum im Format YYYY-MM-DD
    local formattedDate = string.format("%04d-%02d-%02d", year, mon, day)
    -- Zeit im Format HH-MM-SS
    -- local formattedTime = string.format("%02d-%02d-%02d", hour, min, sec)
    local formattedTime = string.format("%02d%02d%02d", hour, min, sec)

    return formattedDate, formattedTime
end

local function getSensors(wgt)
	RSSI = getValue("RSSI")
	RSSImin = getValue("RSSI-")
	VFR = getValue("VFR")
	VFRmin = getValue("VFR-")
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
	ModelRxID2 = model.getModule(0)
	if ModelRxID2.modelId == 0 then
		ModelRxID2 = model.getModule(1)
	end
	ModelRxIDNachher = ModelRxID2.modelId
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			RSSIminsave = 0	
			VFRminsave = 0
		end
	end
	ModelRxID = model.getModule(0)
	if ModelRxID.modelId == 0 then
		ModelRxID = model.getModule(1)
	end
	ModelRxIDVorher = ModelRxID.modelId
end

local function savevalues(wgt)
	newtimerefresh = math.floor(getTime()/100)
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
				io.write(file, "Modell                 : " .. namemodel .. "\nDateiname              : " .. namefile .. "\nRSSImin (dB)           : " .. round(RSSIminsave,0) .. "\nVFRmin (%)             : " .. round(VFRminsave,0) .. "\n")
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
  ShowRSSIMin = wgt.options.ShowRSSIMin
  -- print("ShowRSSIMin"..ShowRSSIMin)
  if wgt.options.ShowVFR ~= 1 then
	lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-00, "RSSI  "..round(RSSI,0), CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+16, "RSSI- "..round(RSSIminsave,0), CUSTOM_COLOR)
  end
  
  if nodataVFR == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  ShowVFR = wgt.options.ShowVFR
  -- print("ShowVFR"..ShowVFR)
  if wgt.options.ShowVFR == 1 then
	lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-00, "VFR  "..round(VFR,0), CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+16, "VFR- "..round(VFRminsave,0), CUSTOM_COLOR)
  end
end

--- Size is 160x32 1/8th
local function refreshZoneSmall(wgt)
  -- print("small 1/8")
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
end

--- Size is 225x98 1/4th  (no sliders/trim)
local function refreshZoneMedium(wgt)
  -- print("medium 1/4")
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText (wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
end

--- Size is 192x152 1/2
local function refreshZoneLarge(wgt)
  -- print("large 1/2")
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
end


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawFilledRectangle(wgt.zone.x+00, wgt.zone.y, 109, 19, CUSTOM_COLOR)
	Modelname = model.getInfo()
	lcd.drawText(wgt.zone.x+00, wgt.zone.y, Modelname.name, SMLSIZE + INVERS + CUSTOM_COLOR)
	mytimer1=model.getTimer(0).value
	lcd.drawText(wgt.zone.x+115, wgt.zone.y,"Motor:   ", SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawTimer(wgt.zone.x+160, wgt.zone.y,mytimer1, SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawFilledRectangle(wgt.zone.x+199, wgt.zone.y, 49, 19, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+199, wgt.zone.y,"RxID: " .. ModelRxIDVorher, SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawFilledRectangle(wgt.zone.x+252, wgt.zone.y, 140, 19, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+254, wgt.zone.y,"RK04-Widget V" .. RKWidgetVersion, SMLSIZE + INVERS + CUSTOM_COLOR)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)

  lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
  -- 1. SENSOR Zeile 1.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+005, wgt.zone.y+20, "RSSI", CUSTOM_COLOR)
    
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
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+20, "VFR", CUSTOM_COLOR)
    
  if nodataVFR == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if VFRminsave == 0 then
  lcd.drawText(wgt.zone.x+290, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+345, wgt.zone.y+20, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+290, wgt.zone.y+20, round(VFR,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+20, round(VFRminsave,0), CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+291, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+18, "%", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+27, "min", SMLSIZE + CUSTOM_COLOR)
    
  -- 2. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+005, wgt.zone.y+50, "", CUSTOM_COLOR)
    
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+50, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+50, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+50, round(Alt,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+50, round(Altmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+101, wgt.zone.y+48, "m", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+48, "m", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+57, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 2. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+50, "", CUSTOM_COLOR)
    
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+50, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+50, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+50, round(RPM,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+50, round(RPMmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+291, wgt.zone.y+48, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+48, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+57, "", SMLSIZE + CUSTOM_COLOR)

  -- 3. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+005, wgt.zone.y+80,"", CUSTOM_COLOR)
  
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+80, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+80, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+80, round(VSpd,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+80, round(mskmh(VSpd),0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+101, wgt.zone.y+78, "m/s", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+78, "km/h", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+87, "min", SMLSIZE + CUSTOM_COLOR)
  
  -- 3. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+80, "", CUSTOM_COLOR)
  
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 and UseCapacitySensor ~=0 then
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+80, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+80, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+80, round(VSpdmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+80, round(mskmh(VSpdmaxsave),0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+291, wgt.zone.y+78, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+78, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+87, "", SMLSIZE + CUSTOM_COLOR)
  
  -- 4. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+005, wgt.zone.y+110, "", SMLSIZE + CUSTOM_COLOR)
    
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+110, round(VSpdmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+110, round(mskmh(VSpdmaxsave),0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+101, wgt.zone.y+108, "m/s", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+108, "km/h", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+117, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 4. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+110, "", CUSTOM_COLOR)
    
  -- if nodataTmp1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Tmp1maxsave == 0 then
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+110, round(Tmp1,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+110, round(Tmp1maxsave,0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+291, wgt.zone.y+108, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+108, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+117, "", SMLSIZE + CUSTOM_COLOR)
  
  -- 5. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+140, "", SMLSIZE + CUSTOM_COLOR)
    
  -- if nodataAlt == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+140, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+140, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+100, wgt.zone.y+140, round(VSpdminsave,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+155, wgt.zone.y+140, round(mskmh(VSpdminsave),0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+101, wgt.zone.y+138, "m/s", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+138, "km/h", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+156, wgt.zone.y+147, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 5. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+140, "", CUSTOM_COLOR)
    
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+140, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+140, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+140, round(RPM,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+140, round(RPMmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- end
  -- lcd.drawText(wgt.zone.x+291, wgt.zone.y+138, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+138, "", SMLSIZE + CUSTOM_COLOR)
  -- lcd.drawText(wgt.zone.x+356, wgt.zone.y+147, "", SMLSIZE + CUSTOM_COLOR)

  -- ===============================================================================================
  -- ===============================================================================================

     
end

function refresh(wgt)

  if (wgt==nil) then
    print("refresh(nil)")
    return
  end

  if (wgt.options==nil) then
    print("refresh(wgt.options=nil)")
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