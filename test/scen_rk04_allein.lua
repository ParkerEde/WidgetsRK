-- Szenario RK04 allein: kein RK01/RK03/RK05 auf dem Screen, also setzt niemand sonst
-- trackswitchcondition. RK04 muss den Motorschutzschalter selbst auswerten und das Log anlegen.
local w, top = makeWidget("RK04", { x = 0, y = 0, w = 70, h = 36 })

SENSORS.sb = -1024  -- Motor gesichert
for step = 1, 120 do
	NOW = NOW + 50
	SENSORS.RSSI = 80; SENSORS["RSSI-"] = 61
	SENSORS.VFR = 100; SENSORS["VFR-"] = 97
	if step == 20 then SENSORS.sb = 1024 end    -- Motor frei (40 s)
	if step == 100 then SENSORS.sb = -1024 end  -- gesichert -> Log
	MARK("STEP", step, tostring(trackswitchcondition), tostring(RK04readysaved))
	safe(w.refresh, top)
end
