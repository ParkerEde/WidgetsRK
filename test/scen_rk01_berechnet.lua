-- Szenario RK01 ohne Kapazitätssensor (UseCapacitySensor = 0): mAh werden aus dem Strom berechnet
local w, full = makeWidget("RK01", { x = 0, y = 0, w = 392, h = 172 }, { UseCapacitySensor = 0, VoiceRepeatTime = 10 })

SENSORS.sb = -1024  -- Motor gesichert
SENSORS.sc = 0
SENSORS.sd = 0

for step = 1, 200 do
	NOW = NOW + 50
	TIMER = step
	-- Telemetrie ab 10, Ausfall 120..130; 4S-Akku
	if step >= 10 and not (step >= 120 and step < 130) then
		SENSORS.VFAS = 16.6 - step * 0.01
		SENSORS["VFAS-"] = 16.4 - step * 0.01
		SENSORS.Curr = (step > 30 and step < 100) and (18 + (step % 9)) or 0
		SENSORS["Curr+"] = 27
		SENSORS.RxBt = 5.0
		SENSORS["RxBt-"] = 4.98
	else
		for _, n in ipairs({ "VFAS", "VFAS-", "Curr", "Curr+", "RxBt", "RxBt-" }) do SENSORS[n] = 0 end
	end
	-- ein Kapazitätssensor wäre da, wird aber nicht benutzt
	SENSORS.EscC = step
	-- Motor frei 25..110, danach gesichert mit Log
	if step == 25 then SENSORS.sb = 1024 end
	if step == 110 then SENSORS.sb = -1024; RK04readysaved = 1; filename = "/LOGS/test.txt" end
	-- Ansage mAh über SC unten
	if step == 15 then SENSORS.sc = 1024 end
	if step == 150 then SENSORS.sc = 0 end
	-- Reset
	SENSORS.ls61 = (step == 160) and 100 or 0

	MARK("STEP", step, tostring(trackswitchcondition), tostring(RK01readysaved))
	if step % 3 == 0 then
		safe(w.background, full)
	else
		safe(w.refresh, full)
	end
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, full) end
end
