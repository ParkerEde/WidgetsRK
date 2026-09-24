-- +++++++++++ RK-Lib: gemeinsame Funktionen der RK-Widgets +++++++++++
-- Wird von jedem Widget per loadScript("/WIDGETS/RK-Lib/RK-Lib.lua")() geladen
-- und liefert eine Tabelle mit den Funktionen zurück.

local lib = {}

-- Muss mit RKWidgetVersion in jedem RKxx/main.lua übereinstimmen,
-- sonst zeigt das Widget nur einen Hinweis an.
lib.version = "1.1.10"

function lib.printTable( t )

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

-- Zahl als Text mit decimal Nachkommastellen (0, 1 oder 2)
function lib.round(num, decimal)
	return string.format("%." .. decimal .. "f", num)
end

-- RxID des aktiven Moduls: erst internes Modul, bei RxID 0 das externe
function lib.getRxID()
	local module = model.getModule(0)
	if module.modelId == 0 then
		module = model.getModule(1)
	end
	return module.modelId
end

-- true, wenn der Motorschutzschalter (RK-Settings) auf "Motor frei" steht
function lib.getTrackSwitchCondition()
	local Track_switch = getValue(activate_tracking_switch)
	local Track_switch_pos = activate_tracking_switch_position
	-- print("Track_switch: " .. Track_switch)
	-- print("Track_switch_pos: " .. Track_switch_pos)
	if activate_tracking_switch_invers == 0 then
		return Track_switch == Track_switch_pos
	else
		return Track_switch ~= Track_switch_pos
	end
end

-- Hinweis für alle Zonen außer Vollbild
function lib.drawNurVollbild(wgt)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x, wgt.zone.y, "nur Vollbild", SMLSIZE + CUSTOM_COLOR)
end

-- Kopfzeile im Vollbild: Modellname, Motor-Timer, RxID, Widget-Version
function lib.drawHeader(wgt, widgetname, version, rxid)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawFilledRectangle(wgt.zone.x+00, wgt.zone.y, 109, 19, CUSTOM_COLOR)
	local Modelname = model.getInfo()
	lcd.drawText(wgt.zone.x+00, wgt.zone.y, Modelname.name, SMLSIZE + INVERS + CUSTOM_COLOR)
	local mytimer1 = model.getTimer(0).value
	lcd.drawText(wgt.zone.x+115, wgt.zone.y,"Motor:   ", SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawTimer(wgt.zone.x+160, wgt.zone.y,mytimer1, SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawFilledRectangle(wgt.zone.x+199, wgt.zone.y, 49, 19, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+199, wgt.zone.y,"RxID: " .. rxid, SMLSIZE + INVERS + CUSTOM_COLOR)
	lcd.drawFilledRectangle(wgt.zone.x+252, wgt.zone.y, 140, 19, CUSTOM_COLOR)
	lcd.drawText(wgt.zone.x+254, wgt.zone.y, widgetname .. "-Widget V" .. version, SMLSIZE + INVERS + CUSTOM_COLOR)
end

-- Eine Wertezeile im Vollbild: Label, aktueller Wert und min/max-Wert.
-- x ist der Spaltenanfang (0 = linke, 200 = rechte Spalte).
-- Ist saved 0, wird "- - " statt der Werte angezeigt.
function lib.drawRow(wgt, x, y, label, nodata, current, saved, decimal)
	lcd.setColor(CUSTOM_COLOR, wgt.options.TextColor)
	lcd.drawText(wgt.zone.x+x, wgt.zone.y+y, label, SMLSIZE + CUSTOM_COLOR)

	if nodata == 1 then lcd.setColor(CUSTOM_COLOR, wgt.options.NoDataColor) end
	if saved == 0 then
		lcd.drawText(wgt.zone.x+x+130, wgt.zone.y+y, "- - ", CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y, "- - ", CUSTOM_COLOR + RIGHT)
	else
		lcd.drawText(wgt.zone.x+x+130, wgt.zone.y+y, lib.round(current,decimal), CUSTOM_COLOR + RIGHT)
		lcd.drawText(wgt.zone.x+x+190, wgt.zone.y+y, lib.round(saved,decimal), CUSTOM_COLOR + RIGHT)
	end
end

return lib
