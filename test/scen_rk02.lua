-- Szenario RK02: Höhe und Vario, Ansage über SC
local w, full = makeWidget("RK02", { x = 0, y = 0, w = 392, h = 172 })
local _, small = makeWidget("RK02", { x = 0, y = 0, w = 160, h = 32 })
local _, top = makeWidget("RK02", { x = 0, y = 0, w = 70, h = 36 })
local _, fast = makeWidget("RK02", { x = 0, y = 0, w = 392, h = 172 }, { VoiceRepeatTime = 5 })

SENSORS.sc = 0
trackswitchcondition = false

for step = 1, 160 do
	NOW = NOW + 50
	TIMER = step
	-- Sensoren
	if step >= 10 and step < 90 then
		SENSORS.Alt = math.floor(step * 1.7) % 120
		SENSORS["Alt+"] = 118
		SENSORS.VSpd = math.sin(step / 5) * 8.3
		if step == 30 then SENSORS.Alt = 2500 end        -- Mondwert Höhe
		if step == 31 then SENSORS.VSpd = 1500 end       -- Mondwert Vario
		if step == 32 then SENSORS.VSpd = -1500 end
	elseif step >= 90 and step < 100 then
		SENSORS.Alt = 0; SENSORS["Alt+"] = 0; SENSORS.VSpd = 0   -- Telemetrie weg
	elseif step >= 100 then
		SENSORS.Alt = 55.4; SENSORS["Alt+"] = 70; SENSORS.VSpd = -2.6
	end
	-- Ansage-Schalter SC: oben, Mitte, unten
	if step == 5 then SENSORS.sc = -1024 end
	if step == 40 then SENSORS.sc = 0 end
	if step == 45 then SENSORS.sc = -1024 end
	if step == 120 then SENSORS.sc = 1024 end
	-- Motor frei / gesichert, Log-Kette: RK01 hat geschrieben
	if step == 20 then trackswitchcondition = true end
	if step == 60 then trackswitchcondition = false; RK01readysaved = 1; filename = "/LOGS/test.txt" end
	if step == 130 then RK01readysaved = 1 end
	-- Reset und Modellwechsel
	SENSORS.ls61 = (step == 70) and 100 or 0
	if step == 80 then RXID[0] = 0; RXID[1] = 7 end
	if step == 140 then RXID[0] = 9 end

	MARK("STEP", step, tostring(RK01readysaved), tostring(RK02readysaved))
	if step % 3 == 0 then
		safe(w.background, full)
	else
		safe(w.refresh, full)
	end
	if step % 10 == 0 then safe(w.refresh, small) end
	if step % 15 == 0 then safe(w.refresh, top) end
	if step % 4 == 0 then safe(w.refresh, fast) end
	-- zweiter Aufruf in derselben Sekunde (Drosselung)
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, full) end
end
