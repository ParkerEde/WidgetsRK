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
local Cels1table = {}
local Pack1 = 0
local Pack1Zelle = {0, 0, 0, 0, 0, 0}
local Pack1ZelleMinSave = {0, 0, 0, 0, 0, 0}

local nodataCels2 = 1
local Cels2table = {}
local Pack2 = 0
local Pack2Zelle = {0, 0, 0, 0, 0, 0}
local Pack2ZelleMinSave = {0, 0, 0, 0, 0, 0}

local ModelRxID = -1
local ModelRxID2 = -1
local ModelRxIDVorher = -1
local ModelRxIDNachher = -1
local Modelname = 0

local alertdone = 0
local timestamp = 0

local newtime = 0
local lasttime_sc = 0
local lasttime_sd = 0
local timestamprefresh = 0

local Track_switch = 0
local Track_switch_pos = 0


local function round(num, decimal)
	if     decimal == 0 then return (string.format("%.0f", num))
	elseif decimal == 1 then return (string.format("%.1f", num))
	elseif decimal == 2 then return (string.format("%.2f", num))
	end
end


local function getSensors(wgt)
	Cels1table = getValue("Cels")
	-- print("===============CELS================")
	-- printTable (Cels1table)
	if Cels1table ~= nil then
		if type(Cels1table) == "table" then
			nodataCels1 = 0
			for i = 1, 6 do
				if Cels1table[i] ~= nil then
					local rawValue = Cels1table[i]
					-- print ("Zelle " .. i .. ": " .. rawValue)
					if rawValue < 1000 then
						Pack1Zelle[i] = rawValue
						
					end
				end
			end
		else
			nodataCels1 = 1
		end
	end
	-- printTable(Pack1Zelle)
	
	Cels2table = getValue("Cel2")
	-- print("===============CEL2================")
	-- printTable (Cels2table)
		if Cels2table ~= nil then
		if type(Cels2table) == "table" then
			nodataCels2 = 0
			for i = 1, 6 do
				if Cels2table[i] ~= nil then
					local rawValue = Cels2table[i]
					-- print ("Zelle " .. i .. ": " .. rawValue)
					if rawValue < 1000 then
						Pack2Zelle[i] = rawValue
						
					end
				end
			end
		else
			nodataCels2 = 1
		end
	end
	-- printTable(Pack2Zelle)
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
			timestamp = 0

			Pack1Zelle = {0, 0, 0, 0, 0, 0}
			Pack1ZelleMinSave = {0, 0, 0, 0, 0, 0}
			
			Pack2Zelle = {0, 0, 0, 0, 0, 0}
			Pack2ZelleMinSave = {0, 0, 0, 0, 0, 0}
		end
	end
	ModelRxID = model.getModule(0)
	if ModelRxID.modelId == 0 then
		ModelRxID = model.getModule(1)
	end
	ModelRxIDVorher = ModelRxID.modelId
end

local function savevalues(wgt)
	-- getSensors(wgt)
	Track_switch = getValue(activate_tracking_switch)
	Track_switch_pos = activate_tracking_switch_position
	-- print("Track_switch: " .. Track_switch)
	-- print("Track_switch_pos: " .. Track_switch_pos)
  
	if activate_tracking_switch_invers == 0 then
		trackswitchcondition = Track_switch == Track_switch_pos
	else
		trackswitchcondition = Track_switch ~= Track_switch_pos
	end
	newtimerefresh = math.floor(getTime()/100)
	if newtimerefresh ~= timestamprefresh then
		-- print("timestamprefresh: " .. timestamprefresh)
		-- print("newtimerefresh: " .. newtimerefresh)
		-- print("------------------------")
		timestamprefresh = newtimerefresh
		getSensors(wgt)  

		for i = 1, #Pack1Zelle do
			if Pack1Zelle[i] ~= 0 then
				if Pack1Zelle[i] < Pack1ZelleMinSave[i] then
					Pack1ZelleMinSave[i] = Pack1Zelle[i]
				end
				if Pack1ZelleMinSave[i] < 2.1 then
					Pack1ZelleMinSave[i] = Pack1Zelle[i]
				end
			end
		end
		
		-- =============================================
		
		for i = 1, #Pack2Zelle do
			if Pack2Zelle[i] ~= 0 then
				if Pack2Zelle[i] < Pack2ZelleMinSave[i] then
					Pack2ZelleMinSave[i] = Pack2Zelle[i]
				end
				if Pack2ZelleMinSave[i] < 2.1 then
					Pack2ZelleMinSave[i] = Pack2Zelle[i]
				end
			end
		end
		-- =============================================
		
		Pack1 = Pack1Zelle[1] + Pack1Zelle[2] + Pack1Zelle[3] + Pack1Zelle[4] + Pack1Zelle[5] + Pack1Zelle[6]
		Pack1minsave = Pack1ZelleMinSave[1] + Pack1ZelleMinSave[2] + Pack1ZelleMinSave[3] + Pack1ZelleMinSave[4] + Pack1ZelleMinSave[5] + Pack1ZelleMinSave[6]
		-- print("Pack1: " .. Pack1)
		-- print("Pack1minsave: " .. Pack1minsave)
		Pack2 = Pack2Zelle[1] + Pack2Zelle[2] + Pack2Zelle[3] + Pack2Zelle[4] + Pack2Zelle[5] + Pack2Zelle[6]
		Pack2minsave = Pack2ZelleMinSave[1] + Pack2ZelleMinSave[2] + Pack2ZelleMinSave[3] + Pack2ZelleMinSave[4] + Pack2ZelleMinSave[5] + Pack2ZelleMinSave[6]
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
	lcd.drawText(wgt.zone.x+254, wgt.zone.y,"RK05-Widget V" .. RKWidgetVersion, SMLSIZE + INVERS + CUSTOM_COLOR)
  --lcd.drawLine(45, 72, 435, 72, 255, 0)
  
	lcd.drawFilledRectangle(wgt.zone.x+194, wgt.zone.y+22, 2, 150, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+140, wgt.zone.y+016, "minimum", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+070, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)	
	lcd.drawText(wgt.zone.x+340, wgt.zone.y+016, "minimum", SMLSIZE + CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+270, wgt.zone.y+016, "momentan", SMLSIZE + CUSTOM_COLOR)
  -- 1. SENSOR Zeile 1.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+030, "Pack 1 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1minsave == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+030, round(Pack1,2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+030, round(Pack1minsave,2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 1. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+030, "Pack 2 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2minsave == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+030, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+030, round(Pack2,2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+030, round(Pack2minsave,2), CUSTOM_COLOR + RIGHT)
  end
    
  -- 2. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+050, "Zelle 01 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[1] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+050, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+050, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+050, round(Pack1Zelle[1],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+050, round(Pack1ZelleMinSave[1],2), CUSTOM_COLOR + RIGHT)
  end
 
  -- 2. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+050, "Zelle 01 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[1] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+050, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+050, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+050, round(Pack2Zelle[1],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+050, round(Pack2ZelleMinSave[1],2), CUSTOM_COLOR + RIGHT)
  end

  -- 3. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+070,"Zelle 02 (V)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataCels1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[2] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+070, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+070, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+070, round(Pack1Zelle[2],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+070, round(Pack1ZelleMinSave[2],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 3. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+070, "Zelle 02 (V)", SMLSIZE + CUSTOM_COLOR)
  
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[2] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+070, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+070, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+070, round(Pack2Zelle[2],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+070, round(Pack2ZelleMinSave[2],2), CUSTOM_COLOR + RIGHT)
  end

  
  -- 4. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+090, "Zelle 03 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[3] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+090, round(Pack1Zelle[3],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+090, round(Pack1ZelleMinSave[3],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 4. SENSOR Zeile 2.Spalte ======================================================================
  -- =============================================================================================== 
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+090, "Zelle 03 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[3] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+090, round(Pack2Zelle[3],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+090, round(Pack2ZelleMinSave[3],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+110, "Zelle 04 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[4] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+110, round(Pack1Zelle[4],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+110, round(Pack1ZelleMinSave[4],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 5. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+110, "Zelle 04 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[4] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+110, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+110, round(Pack2Zelle[4],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+110, round(Pack2ZelleMinSave[4],2), CUSTOM_COLOR + RIGHT)
  end

  -- 6. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+130, "Zelle 05 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[5] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+130, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+130, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+130, round(Pack1Zelle[5],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+130, round(Pack1ZelleMinSave[5],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 6. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+130, "Zelle 05 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[5] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+130, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+130, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+130, round(Pack2Zelle[5],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+130, round(Pack2ZelleMinSave[5],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 7. SENSOR Zeile 1.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)  
  lcd.drawText(wgt.zone.x+000, wgt.zone.y+150, "Zelle 06 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels1 == 1 or nodataAmp ==1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack1ZelleMinSave[6] == 0 then
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+130, wgt.zone.y+150, round(Pack1Zelle[6],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+190, wgt.zone.y+150, round(Pack1ZelleMinSave[6],2), CUSTOM_COLOR + RIGHT)
  end
  
  -- 7. SENSOR Zeile 2.Spalte ======================================================================
  -- ===============================================================================================
  lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
  lcd.drawText(wgt.zone.x+200, wgt.zone.y+150, "Zelle 06 (V)", SMLSIZE + CUSTOM_COLOR)
    
  if nodataCels2 == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
  if Pack2ZelleMinSave[6] == 0 then
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, "- - ", CUSTOM_COLOR + RIGHT)
  else
  lcd.drawText(wgt.zone.x+330, wgt.zone.y+150, round(Pack2Zelle[6],2), CUSTOM_COLOR + RIGHT)
  lcd.drawText(wgt.zone.x+390, wgt.zone.y+150, round(Pack2ZelleMinSave[6],2), CUSTOM_COLOR + RIGHT)
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
    
  
end

return { name="RK05", options=options, create=create, update=update, refresh=refresh, background=background}