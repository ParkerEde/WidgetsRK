-- Szenario RK03: GPS, Entfernung, Strecke, Sats/PDOP (auch MSRC 5100/5101), Link-Prüfung
local w, full = makeWidget("RK03", { x = 0, y = 0, w = 392, h = 172 })
local _, small = makeWidget("RK03", { x = 0, y = 0, w = 160, h = 32 })

SENSORS.sb = -1024  -- Motor gesichert

for step = 1, 220 do
	NOW = NOW + 50
	TIMER = step
	-- Link: FrSky RSSI, ab 120 ELRS TQly, zwischendurch Ausfall
	if step >= 5 and step < 90 then SENSORS.RSSI = 80
	elseif step >= 90 and step < 96 then SENSORS.RSSI = 0
	elseif step >= 96 and step < 120 then SENSORS.RSSI = 75
	elseif step >= 120 then SENSORS.RSSI = 0; SENSORS.TQly = 90; SENSORS["TQly-"] = 60
	end
	-- GPS: Fix ab 15, Modell fliegt eine Runde
	if step >= 15 then
		local a = step / 20
		SENSORS.GPS = { lat = 52.1234567 + math.sin(a) * 0.0015, lon = 8.7654321 + math.cos(a) * 0.0022 }
		SENSORS.GAlt = 112 + math.floor(math.abs(math.sin(a)) * 80)
		SENSORS.GSpd = math.floor(40 + math.abs(math.cos(a)) * 60)
		if step == 40 then SENSORS.GAlt = 25000 end                 -- Mondwert Höhe
		if step == 41 then SENSORS.GSpd = 900 end                   -- Mondwert Speed
		if step == 42 then SENSORS.GPS = { lat = 53.5, lon = 9.9 } end  -- Sprung > 1 km
	end
	-- Satelliten/PDOP: erst FrSky-Namen, dann MSRC-IDs
	if step >= 20 and step < 100 then
		SENSORS.Sats = (step < 50) and 7 or ((step < 70) and 108 or 250)
		SENSORS.PDOP = 150 + step
	elseif step >= 100 then
		SENSORS.Sats = 0; SENSORS.PDOP = 0
		SOURCES["T:5100"] = "S5100"; SOURCES["T:5101"] = "S5101"
		SENSORS.S5100 = (step < 160) and 100 or 112
		SENSORS.S5101 = 95
	end
	-- Motor frei 30..80 und 130..190, danach gesichert mit Log (RK02 fertig)
	if step == 30 then SENSORS.sb = 1024 end
	if step == 80 then SENSORS.sb = -1024; RK02readysaved = 1; filename = "/LOGS/test.txt" end
	if step == 130 then SENSORS.sb = 0 end
	if step == 190 then SENSORS.sb = -1024; RK02readysaved = 1 end
	-- Reset und Modellwechsel
	SENSORS.ls61 = (step == 100) and 100 or 0
	if step == 110 then RXID[0] = 0; RXID[1] = 7 end
	if step == 200 then RXID[0] = 9 end

	MARK("STEP", step, tostring(trackswitchcondition), tostring(RK03readysaved))
	if step % 3 == 0 then
		safe(w.background, full)
	else
		safe(w.refresh, full)
	end
	if step % 10 == 0 then safe(w.refresh, small) end
	-- zweiter Aufruf in derselben Sekunde (Drosselung)
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, full) end
end
