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

local nodataRXBat = 1
local RXBat = 0
local RXBatmin = 0
local RXBatminsave = 0

local nodataUBat = 1
local UBat = 0
local UBatmin = 0
local UBatminsave = 0

local nodataAlt =1
local Alt = 0
local Altmax = 0
local Altmaxsave = 0

local nodataVSpd =1
local VSpd = 0
local VSpdmax = 0
local VSpdmaxsave = 0
local VSpdmin = 0
local VSpdminsave = 0

local nodataRSSI =1
local RSSI = 0
local RSSImin = 0
local RSSIminsave = 0

local ModelRxID = 0
local ModelRxID2 = 0
local ModelRxIDVorher = 0
local ModelRxIDNachher = 0
local Modelname = 0
local cellcountinit = 0
local cellcount = 0

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

local function getSensors(wgt)
	UBat = getValue("VFAS")
	RXBat = getValue("RxBt")
	RXBatmin = getValue("RxBt-")
	Alt = getValue("Alt")
	Altmax = getValue("Alt+")
	VSpd = getValue("VSpd")
	VSpdmax = getValue("VSpd+")
	VSpdmin = getValue("VSpd-")
	RSSI = getValue("RSSI")
	RSSImin = getValue("RSSI-")
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

local function voiceoutput(wgt)
    
	local voiceoutput_sc_switch = getValue(voiceoutputswitch_1)
	local timenow_sc = getTime()

   	if wgt.options.VoiceRepeatTime ~= nil then
		if wgt.options.VoiceRepeatTime == 0 then
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
		if voiceoutput_sc_switch == -1024 then --SC oben
			voicecycletime_sc = voicecycletime_activ
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
	ModelRxIDNachher = ModelRxID2.modelId
	if ModelRxIDVorher ~= 0 then
		local reset = getValue(resetswitch)
		if reset > 0 or ModelRxIDVorher ~= ModelRxIDNachher then
			RXBatminsave = 0
			Altmaxsave = 0
			VSpdmaxsave = 0
			VSpdminsave = 0	
			RSSIminsave = 0	
			cellcount = 0
			cellcountinit = 0
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

  if RXBatmin ~= 0
    then
      RXBatminsave = RXBatmin
      nodataRXBat = 0
	  else
	  nodataRXBat = 1	  
    end

  if Altmax ~= 0
    then
	  Altmaxsave = Altmax
	  nodataAlt = 0
	  else
	  nodataAlt = 1
    end

  if VSpdmax > 0
    then
      VSpdmaxsave = VSpdmax
	  nodataVSpd = 0
	  else
	  nodataVSpd = 1
    end
  
  if VSpdmin < 0
    then
      VSpdminsave = VSpdmin
	end
  	  
	if RSSImin ~= 0
    then
      RSSIminsave = RSSImin
	  nodataRSSI = 0
	  else
	  nodataRSSI = 1
    end
 end
end
------------------------------------------------------------

-- This size is for top bar wgts
local function refreshZoneTiny(wgt)
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  
  if nodataRSSI == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  lcd.drawText(wgt.zone.x+ 0, wgt.zone.y-0, "RSSI", CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+ 0, wgt.zone.y+14, round(RSSI,0), MIDSIZE + CUSTOM_COLOR)
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
  lcd.drawText(wgt.zone.x+5, wgt.zone.y+52, "Alt", CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+43, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+43, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+43, round(Alt,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+43, round(Altmaxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+50, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+50, "m", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+63, "max", SMLSIZE + CUSTOM_COLOR)

  -- 3. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+5, wgt.zone.y+83, "VSpd", CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+72, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+72, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+72, round(VSpd,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+72, round(mskmh(VSpd),0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+79, "m/s", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+79, "km/h", SMLSIZE + CUSTOM_COLOR)
 
  -- 4. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+5, wgt.zone.y+114, "steigen max", CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end  
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+101, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+101, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+101, round(VSpdmaxsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+101, round(mskmh(VSpdmaxsave),0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+108, "m/s", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+108, "km/h", SMLSIZE + CUSTOM_COLOR)
  
  -- 5. SENSOR Zeile ===============================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+5, wgt.zone.y+145, "sinken max", CUSTOM_COLOR)
    
  if nodataAlt == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end  
  if Altmaxsave == 0 then
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+130, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+130, "- - ", DBLSIZE + CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+130, round(VSpdminsave,0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+355, wgt.zone.y+130, round(mskmh(VSpdminsave),0), DBLSIZE + CUSTOM_COLOR + RIGHT)
  end
  lcd.drawText(wgt.zone.x+201, wgt.zone.y+137, "m/s", SMLSIZE + CUSTOM_COLOR)
  lcd.drawText(wgt.zone.x+356, wgt.zone.y+137, "km/h", SMLSIZE + CUSTOM_COLOR)
  
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
  
  -- Sprachausgabe Werte ===========================================================================
  -- ===============================================================================================
  voiceoutput(wgt)
end

return { name="RK02", options=options, create=create, update=update, refresh=refresh, background=background}