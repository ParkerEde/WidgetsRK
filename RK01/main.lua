-- +++++++++++ KONFIGURATIONSTEIL Anfang +++++++++++ 
settings,err = loadScript ("/WIDGETS/RK-Settings/RK-Settings.lua")

if (settings ~= nil) then
     settings()
  else
     print(err)
  end
-- +++++++++++ KONFIGURATIONSTEIL Ende +++++++++++ 

local options = {
  { "TextColor", COLOR, WHITE },
  { "NoDataColor", COLOR, BLACK },
  { "UseCapacitySensor", BOOL, 1},
  { "VoiceRepeatTime", VALUE, 30, 1, 120}
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
local RXBatmin = 0
local RXBatminsave = 0

local nodataUBat = 1
local UBat = 0
local UBatmin = 0
local UBatminsave = 0

local nodataAmp = 1
local Amp = 0
local Ampmax = 0
local Ampmaxsave = 0

local Wattmaxsave = 0

local nodatamAh =1
local mAh = 0
local mAhmax = 0
local mAhmaxsave = 0

local ModelRxID = 0
local ModelRxID2 = 0
local ModelRxIDVorher = 0
local ModelRxIDNachher = 0
local Modelname = 0
local cellcountinit = 0
local cellcount = 0
local alertdone = 0
local timestamp = 0
local mAhcalc = 0
local newtime = 0

local lasttime_sc = 0
local lasttime_sd = 0
local voicecycletime_sc = 20
local voicecycletime_sd = 20
local voicecycletime_activ = 3000
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

local function calcWatt(volt, amps)
    return (volt * amps)
end

local function getSensors(wgt)
	UBat = getValue("VFAS")
	UBatmin = getValue("VFAS-")
	Amp = getValue("Curr")
	Ampmax = getValue("Curr+")
	RXBat = getValue("RxBt")
	RXBatmin = getValue("RxBt-")
	mAh = getValue("A4")
	mAhmax = getValue("A4+")
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
	  -- print("kackspannung: " ..cellaverage(UBatminsave))
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

local function mAhcalculate(current)
    newtime = math.floor(getTime()/100)
	if Amp > 0 then
		if newtime ~= timestamp then
			mAhcalc = (current / 3.6) + mAhcalc
			-- mAhcalc = 1 + mAhcalc
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

local function voiceoutput(wgt)
	local voiceoutput_sc_switch = getValue(voiceoutputswitch_1)
	local timenow_sc = getTime()
   	if wgt.options.VoiceRepeatTime ~= nil then
		if wgt.options.VoiceRepeatTime == 0	then
			wgt.options.VoiceRepeatTime = 30
		end
		voicecycletime_activ = (wgt.options.VoiceRepeatTime * 100)
	else
	end
	
	if voiceoutput_sc_switch == 0 then 
		voicecycletime_sc = 20 
	end
    if ((timenow_sc - lasttime_sc) > voicecycletime_sc) then
		lasttime_sc = timenow_sc
		if voiceoutput_sc_switch == 1024 then --SC unten
			voicecycletime_sc = voicecycletime_activ
			if nodatamAh == 1 then 
				playFile("nodata.wav")
			else
				playNumber(mAhmaxsave, 14)
			end
		end
	end  


	local voiceoutput_sd_switch = getValue(voiceoutputswitch_2)
	local timenow_sd = getTime()
    if voiceoutput_sd_switch == 0 then 
		voicecycletime_sd = 20
	end
    if ((timenow_sd - lasttime_sd) > voicecycletime_sd) then
		lasttime_sd = timenow_sd
		if voiceoutput_sd_switch == -1024 then --SD oben
			voicecycletime_sd = voicecycletime_activ	   
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
			voicecycletime_sd = voicecycletime_activ
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
	ModelRxIDNachher = ModelRxID2.modelId
	if ModelRxIDVorher ~= 0 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			UBatminsave = 0
			Ampmaxsave = 0
			Wattmaxsave = 0
			RXBatminsave = 0
			mAhmaxsave = 0	
			cellcount = 0
			cellcountinit = 0
			alertdone = 0
			timestamp = 0
			mAhcalc = 0
		end
	end
	ModelRxID = model.getModule(0)
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
		if UBat < UBatminsave then
			UBatminsave = UBat
		end
	  	if UBatminsave < 6.1 then
			UBatminsave = UBat
		end
	else
		nodataUBat = 1
	end
	
	if Ampmax ~= 0 then
		Ampmaxsave = Ampmax
		nodataAmp = 0
	else
		nodataAmp = 1
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
		
	if mAhcalc == 0 then
		if mAh ~= 0 then
			mAhmaxsave = mAhmax
			nodatamAh = 0
		else
			nodatamAh = 1
		end
	end
 end
end
------------------------------------------------------------

-- This size is for top bar wgts
local function refreshZoneTiny(wgt)

  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  
  if nodatamAh == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  
  if wgt.options.UseCapacitySensor ~= 0
   then
   -- print("UseCapacitySensor yes")
    lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-0, "mAh", CUSTOM_COLOR)
    lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+14, round(mAhmaxsave,0), MIDSIZE + CUSTOM_COLOR)
  end
  if wgt.options.UseCapacitySensor == 0  
   then
    -- print("UseCapacitySensor no")
    lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-1, "mAh", SMLSIZE + CUSTOM_COLOR)
	-- lcd.drawText(wgt.zone.x+ 35, wgt.zone.y+0, "(C)", SMLSIZE + CUSTOM_COLOR)
    lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+10, round(mAhcalculate(Amp),0), MIDSIZE + CUSTOM_COLOR)
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
  Modelname = model.getInfo()
  lcd.drawText(wgt.zone.x+05, wgt.zone.y, Modelname.name, SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+130, wgt.zone.y, "Zellen: "..cellcount, SMLSIZE + INVERS + CUSTOM_COLOR)
  mytimer1=model.getTimer(0).value
  lcd.drawText(wgt.zone.x+205, wgt.zone.y,"Motor:   ", SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawTimer(wgt.zone.x+253, wgt.zone.y,mytimer1, SMLSIZE + INVERS + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y,"RxID: " .. ModelRxIDVorher, SMLSIZE + INVERS + CUSTOM_COLOR + RIGHT)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)
  
  -- 1. SENSOR Zeile ===============================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+22, "RxBat", CUSTOM_COLOR)
    
  if nodataRXBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if RXBatminsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+15, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+15, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+15, round(RXBat,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+15, round(RXBatminsave,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+20, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+20, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+33, "min", SMLSIZE + CUSTOM_COLOR)
    
  -- 2. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+52, "LiPo", CUSTOM_COLOR)
    
  if nodataUBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if UBatminsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+43, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+43, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+43, round(UBat,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+43, round(UBatminsave,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+50, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+50, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+63, "min", SMLSIZE + CUSTOM_COLOR)

  -- 3. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+005, wgt.zone.y+83,"Volt/Zelle", CUSTOM_COLOR)
  
  if nodataUBat == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if UBatminsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+72, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+72, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+72, round(cellaverage(UBat),2), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+72, round(cellaverage(UBatminsave),2), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+79, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+79, "V", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+92, "min", SMLSIZE + CUSTOM_COLOR)

  -- 4. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+114, "Amp", CUSTOM_COLOR)
    
  if nodataAmp == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Ampmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+101, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+101, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+101, round(Amp,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+101, round(Ampmaxsave,1), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+108, "A", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+108, "A", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+121, "max", SMLSIZE + CUSTOM_COLOR)
  
  -- 5. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+05, wgt.zone.y+145, "Watt", CUSTOM_COLOR)
    
  if nodataUBat == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Wattmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+130, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+130, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+130, round(calcWatt(UBat,Amp),0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+130, round(Wattmaxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+137, "W", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+137, "W", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+150, "max", SMLSIZE + CUSTOM_COLOR)
 
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