-- Szenario RK05: Einzelzellen Cels/Cel2
local w, full = makeWidget("RK05", { x = 0, y = 0, w = 392, h = 172 })
local _, small = makeWidget("RK05", { x = 0, y = 0, w = 160, h = 32 })
local _, top = makeWidget("RK05", { x = 0, y = 0, w = 70, h = 36 })

SENSORS.sb = -1024  -- Motor gesichert

for step = 1, 140 do
	NOW = NOW + 50
	TIMER = step
	-- Sensoren
	if step >= 10 and step < 60 then
		local d = step * 0.01
		SENSORS.Cels = { 4.20 - d, 4.18 - d, 4.21 - d, 4.19 - d }
		if step == 20 then SENSORS.Cels[2] = 1500 end   -- Mondwert
		if step == 22 then SENSORS.Cels[3] = 1.9 end    -- sehr niedrig
		if step >= 32 and step < 40 then for i = 1, 4 do SENSORS.Cels[i] = SENSORS.Cels[i] + 0.15 end end  -- Erholung nach Last
	elseif step >= 60 and step < 70 then
		SENSORS.Cels = 0                                 -- Telemetrie weg
	elseif step >= 70 then
		SENSORS.Cels = { 3.9, 3.8, 3.85, 3.7, 3.75, 3.95 }
		if step >= 85 and step < 100 then for i = 1, 6 do SENSORS.Cels[i] = SENSORS.Cels[i] - 0.3 end end  -- Last
	end
	if step >= 40 and step < 120 then
		local d = step * 0.005
		SENSORS.Cel2 = { 4.1 - d, 4.0 - d, 4.05 - d, 4.1 - d, 4.02 - d, 4.03 - d }
	elseif step >= 120 then
		SENSORS.Cel2 = nil
	end
	-- Motor frei 25..35, danach gesichert; Log-Kette von RK03 simuliert
	if step == 25 then SENSORS.sb = 1024 end
	if step == 36 then SENSORS.sb = -1024; RK03readysaved = 1; filename = "/LOGS/test.txt" end
	if step == 95 then SENSORS.sb = 0 end
	if step == 100 then SENSORS.sb = -1024; RK03readysaved = 1 end
	-- Reset und Modellwechsel
	SENSORS.ls61 = (step == 50) and 100 or 0
	if step == 80 then RXID[0] = 0; RXID[1] = 7 end
	if step == 110 then RXID[0] = 9 end

	MARK("STEP", step, tostring(trackswitchcondition), tostring(RK05readysaved))
	if step % 3 == 0 then
		safe(w.background, full)
	else
		safe(w.refresh, full)
	end
	if step % 10 == 0 then safe(w.refresh, small) end
	if step % 15 == 0 then safe(w.refresh, top) end
	-- zweiter Aufruf in derselben Sekunde (Drosselung)
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, full) end
end
