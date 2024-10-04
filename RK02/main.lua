local RKWidgetVersion = "1.1.06"
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
local Altraw = 0
local Altmax = 0
local Altmaxsave = 0

local nodataVSpd =1
local VSpd = 0
local VSpdraw = 0
local VSpdmax = 0
local VSpdmaxsave = 0
local VSpdmin = 0
local VSpdminsave = 0

local ModelRxID = -1
local ModelRxID2 = -1
local ModelRxIDVorher = -1
local ModelRxIDNachher = -1
local Modelname = 0
local cellcountinit = 0
local cellcount = 0
local lasttime_sc = 0
local lasttime_sd = 0
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

local function mskmh(nummskmh)
    return (nummskmh * 3.6)
end

local function getSensors(wgt)
	Altraw = getValue("Alt")
	if Altraw < 1000 then Alt = Altraw end
	Altmax = getValue("Alt+")
	VSpdraw = getValue("VSpd")
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
	ModelRxID2 = model.getModule(0)
	if ModelRxID2.modelId == 0 then
		ModelRxID2 = model.getModule(1)
	end
	ModelRxIDNachher = ModelRxID2.modelId
	if ModelRxIDVorher ~= -1 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			Altmaxsave = 0
			VSpdmaxsave = 0
			VSpdminsave = 0	
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
		if Altmax ~= 0 then
			if Alt > Altmaxsave then Altmaxsave = Alt end
			nodataAlt = 0
		else
			nodataAlt = 1
		end

		if VSpd > 0 then
			if VSpd > VSpdmaxsave then VSpdmaxsave = VSpd end
			nodataVSpd = 0
		else
			nodataVSpd = 1
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
	lcd.drawText(wgt.zone.x+254, wgt.zone.y,"RK02-Widget V" .. RKWidgetVersion, SMLSIZE + INVERS + CUSTOM_COLOR)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)

	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
  	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)	
	lcd.drawText(wgt.zone.x+340, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+270, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
	
  -- 1. SENSOR Zeile 1.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+030, "Alt (m)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, round(Alt,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, round(Altmaxsave,0), CUSTOM_COLOR + RIGHT)
  end

  
  -- 1. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+030, "", SMLSIZE + CUSTOM_COLOR)
    
  -- if nodataVFR == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if VFRminsave == 0 then
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+345, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+290, wgt.zone.y+030, round(VFR,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+355, wgt.zone.y+030, round(VFRminsave,0), CUSTOM_COLOR + RIGHT)
  -- end
    
  -- 2. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+060+15, "VSpd (m/s)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060+15, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+052+15, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+068+15, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060+15, round(VSpd,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+052+15, round(VSpdminsave,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+067+15, round(VSpdmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 2. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+060, "", SMLSIZE + CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  else
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+060, round(RPM,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, round(RPMmaxsave,0), CUSTOM_COLOR + RIGHT)
  end

  -- 3. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  -- lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  -- lcd.drawText(wgt.zone.x+000, wgt.zone.y+090,"VSpd (km/h)", SMLSIZE + CUSTOM_COLOR)
  
  -- if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+082, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+098, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, round(mskmh(VSpd),0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+083, round(mskmh(VSpdminsave),0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+098, round(mskmh(VSpdmaxsave),0), CUSTOM_COLOR + RIGHT)
  -- end
  
  -- 3. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+090, "", SMLSIZE + CUSTOM_COLOR)
  
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 and UseCapacitySensor ~=0 then
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, round(VSpdmaxsave,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, round(mskmh(VSpdmaxsave),0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 4. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+120,"VSpd (km/h)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+112, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+128, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, round(mskmh(VSpd),0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+112, round(mskmh(VSpdminsave),0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+128, round(mskmh(VSpdmaxsave),0), CUSTOM_COLOR + RIGHT)
  end
 
  
  -- 4. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+120, "", SMLSIZE + CUSTOM_COLOR)
    
  -- if nodataTmp1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Tmp1maxsave == 0 then
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+120, round(Tmp1,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, round(Tmp1maxsave,0), CUSTOM_COLOR + RIGHT)
  -- end
  
  -- 5. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+150, "", SMLSIZE + CUSTOM_COLOR)
    
  -- if nodataAlt == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  -- if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  -- else
  -- lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, round(VSpdminsave,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, round(mskmh(VSpdminsave),0), CUSTOM_COLOR + RIGHT)
  -- end
  
  -- 5. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+150, "", SMLSIZE + CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+150, round(RPM,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, round(RPMmaxsave,0), CUSTOM_COLOR + RIGHT)
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