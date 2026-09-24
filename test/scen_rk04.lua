-- Szenario RK04: RSSI/VFR bzw. RQly/TQly, RSSI-Warnung, Anlegen der Log-Datei
local w, top = makeWidget("RK04", { x = 0, y = 0, w = 70, h = 36 })
local _, topvfr = makeWidget("RK04", { x = 0, y = 0, w = 70, h = 36 }, { ShowVFR = 1 })
local _, nowarn = makeWidget("RK04", { x = 0, y = 0, w = 70, h = 36 }, { RSSIWarning = 0 })
local _, full = makeWidget("RK04", { x = 0, y = 0, w = 392, h = 172 })
local _, small = makeWidget("RK04", { x = 0, y = 0, w = 160, h = 32 })

trackswitchcondition = false

local function setLink(rssi, vfr)
	SENSORS.RSSI = rssi
	SENSORS.VFR = vfr
	if rssi > 0 then
		SENSORS["RSSI-"] = math.min(SENSORS["RSSI-"] or 99, rssi)
		SENSORS["VFR-"] = math.min(SENSORS["VFR-"] or 99, vfr)
	end
end

for step = 1, 260 do
	NOW = NOW + 50
	TIMER = step
	-- FrSky-Link: gut, dann schwächer bis unter 35 und 32, wieder gut, Ausfall
	if step >= 5 and step < 20 then setLink(80, 100)
	elseif step >= 20 and step < 40 then setLink(34, 90)          -- Warnung orange
	elseif step >= 40 and step < 55 then setLink(30, 70)          -- Warnung rot
	elseif step >= 55 and step < 60 then setLink(33, 70)
	elseif step >= 60 and step < 70 then setLink(0, 0)            -- Link weg
	elseif step >= 70 and step < 150 then setLink(70, 95)
	end
	-- ELRS: RQly/TQly tauchen auf und verschwinden wieder
	if step >= 150 and step < 200 then
		SENSORS.RQly = 60 - (step % 40); SENSORS["RQly-"] = 21
		SENSORS.TQly = 80; SENSORS["TQly-"] = 44
		SENSORS.RSSI = 0; SENSORS["RSSI-"] = 0
	elseif step >= 200 then
		SENSORS.RQly = 0; SENSORS["RQly-"] = 0
		SENSORS.TQly = 0; SENSORS["TQly-"] = 0
		setLink(66, 88)
	end
	-- Motor frei: einmal zu kurz (unter 30 s), einmal lang genug
	if step == 75 then trackswitchcondition = true end
	if step == 100 then trackswitchcondition = false end
	if step == 105 then trackswitchcondition = true end
	if step == 180 then trackswitchcondition = false end
	if step == 185 then trackswitchcondition = true end
	if step == 250 then trackswitchcondition = false end
	-- Reset und Modellwechsel
	SENSORS.ls61 = (step == 120) and 100 or 0
	if step == 130 then RXID[0] = 0; RXID[1] = 7 end
	if step == 210 then RXID[0] = 9 end

	MARK("STEP", step, tostring(RK04readysaved), tostring(filename))
	if step % 3 == 0 then
		safe(w.background, top)
	else
		safe(w.refresh, top)
	end
	safe(w.refresh, topvfr)
	if step % 2 == 0 then safe(w.refresh, nowarn) end
	if step % 5 == 0 then safe(w.refresh, full) end
	if step % 20 == 0 then safe(w.refresh, small) end
	-- zweiter Aufruf in derselben Sekunde (Drosselung)
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, top) end
end
