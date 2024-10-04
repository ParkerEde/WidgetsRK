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
  { "UseCapacitySensor", BOOL, 1},
  { "VoiceRepeatTime", VALUE, 30, 1, 120},
  { "SmoothVFAS", VALUE, 1, 1, 10}
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


local nodataRXBat = 1
local RXBat = 0
local RXBatraw = 0
local RXBatmin = 0
local RXBatminsave = 0

local nodataUBat = 1
local UBat = 0
local UBatraw = 0
local UBatmin = 0
local UBatminsave = 0

local nodataAmp = 1
local Amp = 0
local Ampraw = 0
local Ampmax = 0
local Ampmaxsave = 0

local nodataTmp1 = 1
local Tmp1 = 0
local Tmp1raw = 0
local Tmp1max = 0
local Tmp1maxsave = 0

local nodataRPM = 1
local RPM = 0
local RPMraw = 0
local RPMmax = 0
local RPMmaxsave = 0

local Wattmaxsave = 0

local nodatamAh = 1
local mAh = 0
local mAhraw = 0
local mAhmaxsave = 0

local CapaSensorisA4 = 0
local CapaSensorisEscC = 0
local CapaSensorisCapa = 0
local CapaSensorisKapa = 0
local CapaSensoris5123 = 0
local CapaSensor = -1

local ModelRxID = -1
local ModelRxID2 = -1
local ModelRxIDVorher = -1
local ModelRxIDNachher = -1
local Modelname = 0
local cellcountinit = 0
local cellcount = 0
local alertdone = 0
local timestamp = 0
local mAhcalc = 0
local newtime = 0
local lasttime_sc = 0
local lasttime_sd = 0
local timestamprefresh = 0

local Track_switch = 0
local Track_switch_pos = 0

local UBATValuecount=1
local UBATValue={}

local function add_value(new_value)
    -- Füge den neuen Wert zur Liste hinzu
    table.insert(UBATValue, new_value)
    if SmoothVFAS ~= nil then
		UBATValuecount = SmoothVFAS
	else
		UBATValuecount = 1
	end
    -- print ("==========UBATValuecount: " .. UBATValuecount)
	-- Entferne den ältesten Wert, wenn die Fenstergröße überschritten wird
	if #UBATValue > UBATValuecount then
        table.remove(UBATValue, 1)
    end
    -- Berechne den Durchschnitt
    local sum = 0
    for i = 1, #UBATValue do
        sum = sum + UBATValue[i]
    end
    -- Rückgabe des geglätteten Wertes
    return sum / #UBATValue
end

local function round(num, decimal)
	if     decimal == 0 then return (string.format("%.0f", num))
	elseif decimal == 1 then return (string.format("%.1f", num))
	elseif decimal == 2 then return (string.format("%.2f", num))
	end
end

local function mAhcalculate(current)
    newtime = math.floor(getTime()/100)
	if Amp > 0 and UBat > 0 or mAhmaxsave > 0 and UBat > 0 then
		if newtime ~= timestamp then
			mAhcalc = (current / 3.6) + mAhcalc
			mAhmaxsave = mAhcalc
			nodatamAh = 0
			timestamp = newtime
			return mAhmaxsave
		else
			nodatamAh = 0
			return mAhmaxsave
		end
	else
		nodatamAh = 1
		return mAhmaxsave
	end
end

local function mskmh(nummskmh)
    return (nummskmh * 3.6)
end

local function calcWatt(volt, amps)
    return (volt * amps)
end

local function getSensors(wgt)
	UBatraw = getValue("VFAS")
	if UBatraw < 1000 then UBat = UBatraw end
	UBatmin = getValue("VFAS-")
	Ampraw = getValue("Curr")
	if Ampraw < 1000 then Amp = Ampraw end
	Ampmax = getValue("Curr+")
	RXBatraw = getValue("RxBt")
	if RXBatraw < 1000 then RXBat = RXBatraw end
	RXBatmin = getValue("RxBt-")
	Tmp1raw = getValue("Tmp1")
	if Tmp1raw < 1000 then Tmp1 = Tmp1raw end
	Tmp1max = getValue("Tmp1+")
	RPMraw = getValue("RPM")
	if RPMraw < 100000 then RPM = RPMraw end
	RPMmax = getValue("RPM+")
	
	if wgt.options.UseCapacitySensor == 1 then
		if getValue("A4") ~= 0 or CapaSensorisA4 == 1
			then
				CapaSensorisA4 = 1
				mAhraw = getValue("A4")
				-- print("A4: " )
			
		elseif getValue("EscC") ~= 0 or CapaSensorisEscC == 1
			then
				CapaSensorisEscC = 1
				mAhraw = getValue("EscC")
				-- print("EscC: " )
		
		elseif getValue("Capa") ~= 0 or CapaSensorisCapa == 1
			then
				CapaSensorisCapa = 1
				mAhraw = getValue("Capa")
				-- print("Capa: " )			
				
		elseif getValue("Kapa") ~= 0 or CapaSensorisKapa == 1
			then
				CapaSensorisKapa = 1
				mAhraw = getValue("Kapa")
				-- print("Kapa: " )			
				
		elseif getSourceIndex(CHAR_TELEMETRY.."5123") ~= 0 or CapaSensoris5123 == 1
			then
				CapaSensoris5123 = 1
				if CapaSensor == -1 then
					CapaSensor = getSourceIndex(CHAR_TELEMETRY.."5123")
				else
					if CapaSensor ~= nil then mAhraw = getValue(CapaSensor) end
				end
				-- print("5123: " )
		end
		if mAhraw < 100000 then mAh = mAhraw end
	end
end

local function cellcountdetect(wgt)
	Track_switch = getValue(activate_tracking_switch)
	Track_switch_pos = activate_tracking_switch_position
	-- print("Track_switch: " .. Track_switch)
	-- print("Track_switch_pos: " .. Track_switch_pos)
  
	if activate_tracking_switch_invers == 0 then
		trackswitchcondition = Track_switch == Track_switch_pos
	else
		trackswitchcondition = Track_switch ~= Track_switch_pos
	end
	-- print(trackswitchcondition)
	if not trackswitchcondition then
		cellcountinit = 0
		if	   UBat >  2.0 and UBat <=  4.4 then cellcountinit =  1
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
end

local function cellaverage(voltage)
    if cellcount ~= 0 
	then     
    return (voltage / cellcount)
	else
	return 0
	end
end

local function batlow(wgt)
	 if cellcount > 1 and alertdone == 0 and cellaverage(UBatminsave) ~= 0 and cellaverage(UBatminsave) < 3.40
	 then
	  -- print("cellcount: " ..cellcount)
	   playFile("achtun.wav") -- Achtung
	   playFile("SYSTEM/0003.wav") -- 3
	   playFile("SYSTEM/0104.wav") -- Komma
	   playFile("SYSTEM/0004.wav") -- 4
	   playFile("SYSTEM/volt0.wav") -- Volt
	   playFile("percel.wav") -- pro Zelle
	   playFile("quland.wav") -- sofortige Landung empfohlen
	   alertdone = 1
	 end
end

local function voiceoutput(wgt)
	local voiceoutput_sc_switch = getValue(voiceoutputswitch_1)
	local timenow_sc = getTime() + 10000
	-- print ("gettimeSC:" .. timenow_sc)
   	if wgt.options.VoiceRepeatTime ~= nil then
		voicecycletime = (wgt.options.VoiceRepeatTime * 100)
		-- print ("voicecycletime RK01: " .. voicecycletime)
	end
	if voiceoutput_sc_switch == 0 then 
		lasttime_sc = 0
	end
    if ((timenow_sc - lasttime_sc) >= voicecycletime) then
		if voiceoutput_sc_switch == 1024 then --SC unten
			lasttime_sc = timenow_sc
			if nodatamAh == 1 then 
				playFile("nodata.wav")
			else
				playNumber(mAhmaxsave, 14)
			end
		end
	end

	local voiceoutput_sd_switch = getValue(voiceoutputswitch_2)
	local timenow_sd = getTime() + 10000
	-- print ("gettimeSD:" .. timenow_sd)
    if voiceoutput_sd_switch == 0 then 
		lasttime_sd = 0
	end
    if ((timenow_sd - lasttime_sd) >= voicecycletime) then
		if voiceoutput_sd_switch == -1024 then --SD oben
			lasttime_sd = timenow_sd
			if nodataAmp == 1 and nodataUBat == 1 then 
				playFile("nodata.wav")
			else
				if nodataAmp == 0 then 
					playFile("maximu.wav")
					playNumber(round(Ampmaxsave,0), 2)
					playFile("06sek.wav")
				end
				playFile("minimu.wav")
				playNumber(((round(cellaverage(UBatminsave),1))*10), 1, PREC1)
				playFile("percel.wav")
			end
		end
		if voiceoutput_sd_switch == 1024 then --SD unten
			lasttime_sd = timenow_sd
			if nodataAmp == 1 and nodataUBat == 1 then 
				playFile("nodata.wav")
			else
				playFile("moment.wav")
				if nodataAmp == 0 then
					playNumber(round(Amp,0), 2)
					playFile("06sek.wav")
				end
				playNumber(((round(cellaverage(UBat),1))*10), 1, PREC1)
				playFile("percel.wav")
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
			UBatminsave = 0
			Ampmaxsave = 0
			Tmp1maxsave = 0
			RPMmaxsave = 0
			Wattmaxsave = 0
			RXBatminsave = 0
			mAhmaxsave = 0	
			mAhcalc = 0			
			cellcount = 0
			cellcountinit = 0
			alertdone = 0
			timestamp = 0
			CapaSensorisA4 = 0
			CapaSensorisEscC = 0
			CapaSensorisCapa = 0
			CapaSensorisKapa = 0
			CapaSensoris5123 = 0
			CapaSensor = -1
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
		if UBatmin ~= 0 or UBat ~= 0 then
			nodataUBat = 0
			UBatsmooth = add_value(UBat)
			if UBatsmooth < UBatminsave then
				UBatminsave = UBatsmooth
				-- UBatminsave = add_value(UBat)			
			end
			if UBatminsave < 6.1 then
				UBatminsave = UBat
			end
		else
			nodataUBat = 1
		end
	
		if Ampmax ~= 0 then
			if Amp > Ampmaxsave then Ampmaxsave = Amp end
			nodataAmp = 0
		else
			nodataAmp = 1
		end
	
		if Tmp1max ~= 0 then
			if Tmp1 > Tmp1maxsave then Tmp1maxsave = Tmp1 end
			nodataTmp1 = 0
		else
			nodataTmp1 = 1
		end
	
		if RPMmax ~= 0 then
			if RPM > RPMmaxsave then RPMmaxsave = RPM end
			nodataRPM = 0
		else
			nodataRPM = 1
		end
	
		if calcWatt(UBat,Amp) > Wattmaxsave then 
			Wattmaxsave = calcWatt(UBat,Amp)
		end
	
		if RXBatmin ~= 0 then
			RXBatminsave = RXBatmin
			nodataRXBat = 0
		else
			nodataRXBat = 1	  
		end
		
		if UseCapacitySensor == nil then print("UseCapacitySensor = nil")
		elseif UseCapacitySensor == 1 then
			if mAhcalc == 0 then
				if mAh ~= 0 then
					-- print("mAh~=0: " .. mAh)
					if mAh > mAhmaxsave then mAhmaxsave = mAh end
					nodatamAh = 0
				else
				nodatamAh = 1
				end
			end
		end
		
		if not trackswitchcondition and RK04readysaved == 1 then
			local file, err = io.open(filename, "a")
			if file then
				io.write(file, "RXBatmin (V)           : " .. round(RXBatminsave,2) .. "\nAnzahl Zellen          : " .. cellcount .. "\nUBatmin (V)            : " .. round(UBatminsave,2) .. "\nVolt pro Zelle (V)     : " .. round(cellaverage(UBatminsave),2) .. "\nAmpmax (A)             : " .. round(Ampmaxsave,2) .. "\nWattmax (W)            : " .. round(Wattmaxsave,0) .. "\nKapa (mAh)             : " .. round(mAhmaxsave,0) .. "\nTMP1max (°C)           : " .. round(Tmp1maxsave,0) .. "\nRPMmax (U/min)         : " .. round(RPMmaxsave,0) .. "\n")
				io.close(file)
				RK01readysaved = 1
				RK02readysaved = 0
				RK03readysaved = 0
				RK04readysaved = 0
				-- print("Datei erfolgreich gespeichert: " .. filename)
			else
				print("Fehler beim Öffnen der Datei: " .. tostring(err))
			end
		end
	end
	SmoothVFAS = wgt.options.SmoothVFAS
	UseCapacitySensor = wgt.options.UseCapacitySensor
	if wgt.options.UseCapacitySensor ~= 1 then mAhcalculate(Amp) end
	
end
------------------------------------------------------------

-- This size is for top bar wgts
local function refreshZoneTiny(wgt)

  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
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
	lcd.drawText(wgt.zone.x+254, wgt.zone.y,"RK01-Widget V" .. RKWidgetVersion, SMLSIZE + INVERS + CUSTOM_COLOR)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)
  
	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)	
	lcd.drawText(wgt.zone.x+340, wgt.zone.y+016, "min/max", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+270, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
  -- 1. SENSOR Zeile 1.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+030, "RxBat (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataRXBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if RXBatminsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, round(RXBat,2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, round(RXBatminsave,2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 1. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+030, "Kapa (mAh)", SMLSIZE + CUSTOM_COLOR)
    
  if nodatamAh == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if mAhmaxsave == 0 and UseCapacitySensor ~=0 then
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+ 390, wgt.zone.y+030, round(mAhmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
    
  -- 2. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+060, "LiPo (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataUBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if UBatminsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+060, round(UBat,2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+060, round(UBatminsave,2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 2. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+060, "RPM (U/min)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataRPM == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if RPMmaxsave == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+060, round(RPM,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+060, round(RPMmaxsave,0), CUSTOM_COLOR + RIGHT)
  end

  -- 3. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+090,"LiPo/"..cellcount .. " (V)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataUBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if UBatminsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, round(cellaverage(UBat),2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, round(cellaverage(UBatminsave),2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 3. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+090, "Tmp1 (C)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataTmp1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Tmp1maxsave == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, round(Tmp1,0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, round(Tmp1maxsave,0), CUSTOM_COLOR + RIGHT)
  end

  
  -- 4. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+120, "Strom (A)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataAmp == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Ampmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+120, round(Amp,1), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+120, round(Ampmaxsave,1), CUSTOM_COLOR + RIGHT)
  end
  
  -- 4. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+120, "", SMLSIZE + CUSTOM_COLOR)
    
  if nodataTmp1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Tmp1maxsave == 0 then
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, "- - ", CUSTOM_COLOR + RIGHT)
  else
  -- lcd.drawText(wgt.zone.x+330, wgt.zone.y+120, round(Tmp1,0), CUSTOM_COLOR + RIGHT)
  -- lcd.drawText(wgt.zone.x+390, wgt.zone.y+120, round(Tmp1maxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+150, "Watt (W)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataUBat == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Wattmaxsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, round(calcWatt(UBat,Amp),0), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, round(Wattmaxsave,0), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+150, "", SMLSIZE + CUSTOM_COLOR)
    
  if nodataRPM == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if RPMmaxsave == 0 then
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
  
  -- Anzahl Zellen im Vordergrund ermitteln ========================================================
  -- ===============================================================================================
  cellcountdetect(wgt)
  
  -- RESET nach "LS61" oder Modellwechsel eigener Screen ============================================
  -- ===============================================================================================
  resetvalues(wgt)
  
  -- Soundmeldung wenn UBAT < 3.4 Volt =============================================================
  -- ===============================================================================================
  batlow(wgt)
  
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

    -- Anzahl Zellen im Hintergrund ermitteln ========================================================
    -- ===============================================================================================
    cellcountdetect(wgt)
  
    -- RESET nach "LS61" wenn im Hintergrund ==========================================================
    -- ===============================================================================================
    resetvalues(wgt)
    
    -- Soundmeldung wenn UBAT < 3.4 Volt =============================================================
  -- ===============================================================================================
    batlow(wgt)
  
    -- Sprachausgabe Werte ===========================================================================
    -- ===============================================================================================
    voiceoutput(wgt)
  
end

return { name="RK01", options=options, create=create, update=update, refresh=refresh, background=background}