-- +++++++++++ KONFIGURATIONSTEIL Anfang +++++++++++ 
-- es müssen kleine Buchstaben verwendet werden! Die Angabe muss in Anführungszeichen eingefasst sein!

-- logischer Schalter, mit dem der Reset ausgelöst werden soll
local resetswitch = "ls61"

-- Schalter, mit dem die Berechnung der "geflogenen Strecke" gestartet werden soll (z.B. Motorschutzschalter default = "sb")
local activate_tracking_switch = "sb"
-- Position angeben, bei dem berechnet werden soll: 1024 = unten ; 0 = mitte ; -1024 = oben
local activate_tracking_switch_position = -1024
-- Wenn nur eine Schalterposition ausgeschlossen werden soll dann 1 (und auszuschließende Pos oben angeben), sonst 0
local activate_tracking_switch_invers = 1

-- +++++++++++ KONFIGURATIONSTEIL Ende +++++++++++ 

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

local ModelRxID = 0
local ModelRxID2 = 0
local ModelRxIDVorher = 0
local ModelRxIDNachher = 0
local Modelname = 0
local UBat = 0
local cellcountinit = 0
local cellcount = 0

local nodataRSSI = 1
local RSSImin = 0
local RSSIminsave = 0

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

local timestamp = 0
local newtime = 0
local gpsfixmessagedone = 0
local Track = 0
local Track_switch = 0
local Track_switch_pos = 0

local Satssave = 0
local PDOPsave = 0

local function round(num, decimal)
	if     decimal == 0 then return (string.format("%.0f", num))
	elseif decimal == 1 then return (string.format("%.1f", num))
	elseif decimal == 2 then return (string.format("%.2f", num))
	end
end

local function getSensors(wgt)
	RxBt = getValue("RxBt")
	UBat = getValue("VFAS")
	GSpd = getValue("GSpd")
	GAlt = getValue("GAlt")
	RSSImin = getValue("RSSI-")
	Sats = getValue("Tmp1")
	PDOP = getValue("Tmp2")
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

local function cellcountdetect(wgt)
    cellcountinit = 0
	if      UBat >  2.0 and UBat <=  4.4 then cellcountinit =  1
	 elseif UBat >  4.4 and UBat <=  8.6 then cellcountinit =  2
	 elseif UBat >  8.6 and UBat <= 12.8 then cellcountinit =  3
	 elseif UBat > 12.8 and UBat <= 17.1 then cellcountinit =  4
	 elseif UBat > 17.1 and UBat <= 21.3 then cellcountinit =  5
	 elseif UBat > 21.3 and UBat <= 25.6 then cellcountinit =  6
	 elseif UBat > 25.6 and UBat <= 29.8 then cellcountinit =  7
	 elseif UBat > 29.8 and UBat <= 34.1 then cellcountinit =  8
	 elseif UBat > 34.1 and UBat <= 38.3 then cellcountinit =  9
	 elseif UBat > 38.3 and UBat <= 42.6 then cellcountinit = 10
	 elseif UBat > 42.6 and UBat <= 46.8 then cellcountinit = 11
	 elseif UBat > 46.8 and UBat <= 51.1 then cellcountinit = 12
	end
	if cellcount == 0 or cellcountinit > cellcount then cellcount = cellcountinit end
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
	ModelRxIDNachher = ModelRxID2.modelId
	if ModelRxIDVorher ~= 0 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			gpsValuelat1 = "no Data"
			gpsValuelon1 = "no Data"
			gpsValuelat2 = "no Data"
			gpsValuelon2 = "no Data"
			gpsValuelat3 = "no Data"
			gpsValuelon3 = "no Data"
			RSSIminsave = 0	
			cellcount = 0
			cellcountinit = 0
			GSpdmaxsave = 0
			GAltmaxsave = 0
			GAltOffsetdone = 0
			GAl2 = 0
			GAl2maxsave = 0
			DisMmaxsave = 0
			DisGmaxsave = 0	
			gpsfixmessagedone = 0
			Track = 0
			Sats_seen = 0
		end
	end
	ModelRxID = model.getModule(0)
	ModelRxIDVorher = ModelRxID.modelId
end

local function savevalues(wgt)
	getSensors(wgt)  

  
	if GSpd > GSpdmaxsave and GSpd < 1000 then 
		GSpdmaxsave = GSpd
	end
	
	if Sats > 0 and Sats < 100 then 
		Satssave = Sats
	end

	if PDOP > 0 and PDOP < 1000 then 
		PDOPsave = PDOP
	end

	if GAlt > GAltmaxsave and GAlt < 10000 then
		GAltmaxsave = GAlt
	else
		if GAltmaxsave > 0 then
			nodataGAlt = 0
		else
			nodataGAlt = 1
		end
    end

-- print("GAl2: " .. GAl2)
-- print("GAltOffset: " .. GAltOffset)
	if GAltOffsetdone == 0 and GAlt > 0 then
		GAltOffset = GAlt
		GAltOffsetdone = 1
	end
  
	if GAltOffsetdone == 1 and RxBt > 0 then
		GAl2 = GAlt - GAltOffset
	end	
	if RxBt == 0 then
	GAl2 = 0
	DisG = 0
	DisM = 0
	nodataGAlt = 1
	end
	
	if GAl2 > GAl2maxsave and GAl2 < 10000 then
		GAl2maxsave = GAl2
    end
	
	newtime = math.floor(getTime()/100)
	-- print("newtime: " .. newtime)
	if newtime ~= timestamp then
		-- print("timestamp: " .. timestamp)
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
		timestamp = newtime
	end
	  
	if RSSImin ~= 0 then
		RSSIminsave = RSSImin
		nodataRSSI = 0
	else
		nodataRSSI = 1
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
  savevalues(wgt)
  resetvalues(wgt)  
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  
  if nodataRSSI == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+0, "RSSI-", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+15, round(RSSIminsave,0), MIDSIZE + CUSTOM_COLOR)
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
	lcd.drawText(wgt.zone.x+05, wgt.zone.y-000,  "GPS Pos Start:", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+05, wgt.zone.y+045, "GPS Pos Modell:", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+05, wgt.zone.y+090, "Strecke:", SMLSIZE + CUSTOM_COLOR)    
	if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end

	if gpsValuelat1 ~= "no Data" 
		then
		-- lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y-000, gpsValuelat1..",", CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+020, gpsValuelon1, CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+045, gpsValuelat2..",",   CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+065, gpsValuelon2, CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+090, round(Track,0) .. "m", CUSTOM_COLOR)
		else
		-- lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y-000, "keine Daten", SMLSIZE + CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+045, "keine Daten", SMLSIZE + CUSTOM_COLOR)
		lcd.drawText(wgt.zone.x+105, wgt.zone.y+090, "keine Daten", SMLSIZE + CUSTOM_COLOR)
	end

  if Sats > 0 or Sats_seen == 1
	then
	Sats_seen = 1
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+05, wgt.zone.y+110, "Satelliten:", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+05, wgt.zone.y+130, "PDOP (<2):", SMLSIZE + CUSTOM_COLOR)
	if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	lcd.drawText(wgt.zone.x+105, wgt.zone.y+110, Satssave, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+105, wgt.zone.y+130, round((PDOPsave/255)*25.5,2), CUSTOM_COLOR)  	
  end
  
end


--- Size is 390x172 1/1
--- Size is 460x252 1/1 (no sliders/trim/topbar)
local function refreshZoneXLarge(wgt)
  
  -- MinMax Werte im Vordergrund sichern ===========================================================
  -- ===============================================================================================
  savevalues(wgt)
  
  -- Anzahl Zellen im Vordergrund ermitteln ========================================================
  -- ===============================================================================================
  cellcountdetect(wgt)
  
  -- RESET nach "LS61" oder Modellwechsel eigener Screen ============================================
  -- ===============================================================================================
  resetvalues(wgt)
  
  -- GPS Daten im Vordergrund ermitteln ============================================================
  -- ===============================================================================================      
  GetGPSData(wgt)
  
  -- GPS Fix Soundmessage ==========================================================================
  -- ===============================================================================================  
  gpsfixmessage(wgt)
  
  -- 1. Zeile Modellname , Rx ID ===================================================================
  -- ===============================================================================================
  
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  Modelname = model.getInfo()
  lcd.drawText(wgt.zone.x+05, wgt.zone.y, Modelname.name, SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+130, wgt.zone.y, "Zellen: "..cellcount, SMLSIZE + INVERS + CUSTOM_COLOR)
  mytimer1=model.getTimer(0).value
  lcd.drawText(wgt.zone.x+205, wgt.zone.y,"Motor:  ", SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawTimer(wgt.zone.x+253, wgt.zone.y,mytimer1, SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y,"RxID: " .. ModelRxIDVorher, SMLSIZE + INVERS + CUSTOM_COLOR + RIGHT)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)
  
  
  -- 1. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+22, "GSpd", CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+17, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+17, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+17, round(GSpd,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+17, round(GSpdmaxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+20, "km/h", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+20, "km/h", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+33, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 2. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+52, "GAlt NN", CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+47, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+47, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+47, round(GAlt,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+47, round(GAltmaxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+50, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+50, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+63, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 3. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+83, "GAlt Gnd", CUSTOM_COLOR)
    
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+78, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+78, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+78, round(GAl2,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+78, round(GAl2maxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+81, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+81, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+94, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 4. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+114, "Dist Gnd", CUSTOM_COLOR)
  
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end  
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+109, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+109, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+109, DisG, DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+109, DisGmaxsave, DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+112, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+112, "m", SMLSIZE + CUSTOM_COLOR)  
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+125, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 5. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+145, "Dist Mod", CUSTOM_COLOR)
  
  if nodataGAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if GAltmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+140, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+140, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+140, DisM, DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+140, DisMmaxsave, DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+143, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+143, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+156, "max", SMLSIZE + CUSTOM_COLOR)
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

  -- Anzahl Zellen im Hintergrund ermitteln ========================================================
  -- ===============================================================================================
  cellcountdetect(wgt)
  
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