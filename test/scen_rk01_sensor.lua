-- Szenario RK01 mit Kapazitätssensor (UseCapacitySensor = 1): Akku, Strom, RPM, Tmp1,
-- Zellenzahl, Unterspannungsalarm, Ansagen SC/SD, Sensorsuche A4/EscC/Capa/Kapa/5123
local w, full = makeWidget("RK01", { x = 0, y = 0, w = 392, h = 172 }, { SmoothVFAS = 3 })
local _, small = makeWidget("RK01", { x = 0, y = 0, w = 160, h = 32 })

SENSORS.sb = -1024  -- Motor gesichert
SENSORS.sc = 0
SENSORS.sd = 0

local capa = 0
for step = 1, 300 do
	NOW = NOW + 50
	TIMER = step
	-- Telemetrie ab 10, Ausfall 150..160
	if step >= 10 and not (step >= 150 and step < 160) then
		local t = step / 10
		local volt = 25.1 - step * 0.012                   -- 6S, sinkt langsam
		if step > 60 and step < 120 then volt = volt - 2.5 end  -- Last
		SENSORS.VFAS = volt
		SENSORS["VFAS-"] = volt - 0.1
		SENSORS.Curr = (step > 60 and step < 120) and (35 + math.sin(t) * 10) or 1.2
		SENSORS["Curr+"] = 46
		SENSORS.RxBt = 5.1 - (step % 7) * 0.01
		SENSORS["RxBt-"] = 5.02
		SENSORS.Tmp1 = 25 + math.floor(step / 10)
		SENSORS["Tmp1+"] = 55
		SENSORS.RPM = (step > 60 and step < 120) and 21000 + step or 0
		SENSORS["RPM+"] = 21200
		capa = capa + SENSORS.Curr / 7.2
		if step == 70 then SENSORS.VFAS = 1500 end          -- Mondwerte
		if step == 71 then SENSORS.Curr = 2000 end
		if step == 72 then SENSORS.RPM = 250000 end
		if step == 73 then SENSORS.Tmp1 = 1200 end
	else
		for _, n in ipairs({ "VFAS", "VFAS-", "Curr", "Curr+", "RxBt", "RxBt-", "Tmp1", "Tmp1+", "RPM", "RPM+" }) do SENSORS[n] = 0 end
	end
	-- Kapazitätssensor: erst EscC, nach Reset nur MSRC 5123, nach Modellwechsel A4, dann Kapa
	SENSORS.A4 = 0; SENSORS.EscC = 0; SENSORS.Kapa = 0
	if step >= 10 and step < 130 then SENSORS.EscC = math.floor(capa) end
	if step >= 135 and step < 200 then SOURCES["T:5123"] = "S5123"; SENSORS.S5123 = math.floor(capa) end
	if step >= 205 and step < 250 then SENSORS.A4 = math.floor(capa) end
	if step >= 255 then SENSORS.Kapa = math.floor(capa) end
	-- Unterspannung: ab 230 unter 3,4 V pro Zelle
	if step >= 230 and step < 240 then SENSORS.VFAS = 19.8; SENSORS["VFAS-"] = 19.7 end
	-- Motor frei 40..125, danach gesichert mit Log (RK04 hat die Datei angelegt)
	if step == 40 then SENSORS.sb = 1024 end
	if step == 125 then SENSORS.sb = -1024; RK04readysaved = 1; filename = "/LOGS/test.txt" end
	if step == 260 then SENSORS.sb = 0 end
	if step == 280 then SENSORS.sb = -1024; RK04readysaved = 1 end
	-- Ansagen: SC unten (mAh), SD oben (min/max), SD unten (momentan)
	if step == 20 then SENSORS.sc = 1024 end
	if step == 90 then SENSORS.sc = 0 end
	if step == 95 then SENSORS.sc = 1024 end
	if step == 100 then SENSORS.sc = 0; SENSORS.sd = -1024 end
	if step == 170 then SENSORS.sd = 1024 end
	if step == 240 then SENSORS.sd = 0 end
	-- Reset und Modellwechsel
	SENSORS.ls61 = (step == 132) and 100 or 0
	if step == 202 then RXID[0] = 0; RXID[1] = 7 end
	if step == 252 then RXID[0] = 9 end

	MARK("STEP", step, tostring(trackswitchcondition), tostring(RK01readysaved))
	if step % 3 == 0 then
		safe(w.background, full)
	else
		safe(w.refresh, full)
	end
	if step % 10 == 0 then safe(w.refresh, small) end
	-- zweiter Aufruf in derselben Sekunde (Drosselung)
	if step % 7 == 0 then NOW = NOW + 10; safe(w.refresh, full) end
end
