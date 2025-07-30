local RKWidgetVersion = "1.1.09"
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

local ModelRxID = -1
local ModelRxID2 = -1
local ModelRxIDVorher = -1
local ModelRxIDNachher = -1
local Modelname = 0

local GSpd = 0
local GSpdraw = 0
local GSpdmaxsave = 0

local nodataGAlt = 1
local GAlt = 0
local GAltraw = 0
local GAltmaxsave = 0
local GAltOffsetdone = 0
local GAltOffset = 0

local GAl2 = 0
local GAl2maxsave = 0

local DisM = 0
local DisG = 0
local DisMmaxsave = 0
local DisGmaxsave = 0

local timestamp = 0
local newtime = 0
local gpsfixmessagedone = 0
local Track = 0
local Track_switch = 0
local Track_switch_pos = 0

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

local function round(num, decimal)
	if     decimal == 0 then return (string.format("%.0f", num))
	elseif decimal == 1 then return (string.format("%.1f", num))
	elseif decimal == 2 then return (string.format("%.2f", num))
	end
end
	
local function getSensors(wgt)

	if getValue("TQly-") > 0 then
		RSSI = getValue("TQly")
	else
		RSSI = getValue("RSSI")

	end
	
	GSpdraw = getValue("GSpd")
	if GSpdraw < 300 then GSpd = GSpdraw end
	
	GAltraw = getValue("GAlt")
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
	
	Track_switch = getValue(activate_tracking_switch)
	Track_switch_pos = activate_tracking_switch_position
	-- print("Track_switch: " .. Track_switch)
	-- print("Track_switch_pos: " .. Track_switch_pos)
  
	if activate_tracking_switch_invers == 0 then
		trackswitchcondition = Track_switch == Track_switch_pos
	else
		trackswitchcondition = Track_switch ~= Track_switch_pos
	end
	
end



  -- GPS Daten ermitteln und DisG und DisM berechnen ========================================
  -- <BEGIN> ================================================================================
local gpsValuelat1 = "no Data"
local gpsValuelon1 = "no Data"
local gpsValuelat2 = "no Data"
local gpsValuelon2 = "no Data"
local gpsValuelat3 = "no Data"
local gpsValuelon3 = "no Data"

local function rnd(v,d)
    if d then
     return math.floor((v*10^d)+0.5)/(10^d)
    else
     return math.floor(v+0.5)
    end
end

local function getTelemetryId(name)
    field = getFieldInfo(name)
    if field then
      return field.id
    else
      return -1
    end
end

local function GetGPSData(wgt)
 newtimegps = math.floor(getTime()/100)
 if newtimegps ~= timestampgps then
 timestampgps = newtimegps

	local gpsId = getTelemetryId("GPS")
	gpsLatLon = getValue(gpsId)
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

local function calcDisG(lat1, lon1, lat2, lon2)
    if gpsValuelat1 ~= "no Data" and gpsValuelon1 ~= "no Data" and gpsValuelat2 ~= "no Data" and gpsValuelon2 ~= "no Data" then
		local lat = math.cos((lat1 + lat2) / 2 * 0.01745)
		local dx = math.abs(111.3 * lat * (lon1 - lon2))
		local dy = math.abs(111.3 * (lat1 - lat2))
		return math.sqrt(dx*dx + dy*dy) * 1000
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
	ModelRxID2 = model.getModule(0)
	if ModelRxID2.modelId == 0 then
		ModelRxID2 = model.getModule(1)
	end
	ModelRxIDNachher = ModelRxID2.modelId
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
	ModelRxID = model.getModule(0)
	if ModelRxID.modelId == 0 then
		ModelRxID = model.getModule(1)
	end
	ModelRxIDVorher = ModelRxID.modelId
end

local function savevalues(wgt)
  newtimerefresh = math.floor(getTime()/100)

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
	
	if calcDisG(gpsValuelat1,gpsValuelon1,gpsValuelat2,gpsValuelon2) < 10000 then
		DisG = rnd(calcDisG(gpsValuelat1,gpsValuelon1,gpsValuelat2,gpsValuelon2),0)
		if DisG > DisGmaxsave then
			DisGmaxsave = DisG
		end
	end
	if calcDisM(DisG,GAl2) < 10000	then
		DisM = rnd(calcDisM(DisG,GAl2), 0)
		if DisM > DisMmaxsave then
			DisMmaxsave = DisM
		end
	end
	
	if trackswitchcondition then
		if gpsValuelat2 ~= "no Data" and gpsValuelon2 ~= "no Data" and gpsValuelat3 ~= "no Data" and gpsValuelon3 ~= "no Data" then
			-- print("Track vorher: " .. Track)
			local lat = math.cos((gpsValuelat3 + gpsValuelat2) / 2 * 0.01745)
			local dx = math.abs(111.3 * lat * (gpsValuelon3 - gpsValuelon2))
			local dy = math.abs(111.3 * (gpsValuelat3 - gpsValuelat2))
			local Tracknew = math.sqrt(dx*dx + dy*dy) * 1000
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
local function refreshZoneTiny(wgt)
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText (wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
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
  lcd.drawText (wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
	

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
	lcd.drawText(wgt.zone.x+254, wgt.zone.y,"RK03-Widget V" .. RKWidgetVersion, SMLSIZE + INVERS + CUSTOM_COLOR)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)
  
  lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
  -- 1. SENSOR Zeile 1.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+030, "GSpd (km/h)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, round(GSpd,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, round(GSpdmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 1. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+030, "Start-Position", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if gpsValuelat1 == "no Data" then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+045, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+030, gpsValuelat1, SMLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+045, gpsValuelon1, SMLSIZE + CUSTOM_COLOR + RIGHT)
  end
    
  -- 2. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+060, "GAlt NN (m)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060, round(GAlt,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+060, round(GAltmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 2. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+060, "Modell-Position", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if gpsValuelat1 == "no Data" then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+075, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, gpsValuelat2, SMLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+075, gpsValuelon2, SMLSIZE + CUSTOM_COLOR + RIGHT)
  end

  -- 3. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+090,"GAlt Gnd (m)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, round(GAl2,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, round(GAl2maxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 3. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+090, "geflogene Strecke (m)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, round(Track,0), CUSTOM_COLOR + RIGHT)
  end
  -- lcd.drawText(wgt.zone.x+376, wgt.zone.y+093, "m", SMLSIZE + CUSTOM_COLOR)
  
  -- 4. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+120, "Dist Gnd (m)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, round(DisG,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+120, round(DisGmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 4. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+120, "Satelliten", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if SatsSeen ~= 1 then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, round(Satssave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+150, "Dist Mod (m)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, round(DisM,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, round(DisMmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+150, "PDOP (ideal <2.00)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if PDOPSeen ~= 1 then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, round(PDOPsave,2), CUSTOM_COLOR + RIGHT)
  end

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