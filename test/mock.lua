-- EdgeTX-Nachbildung für Vergleichstests. ROOT wird von harness.py gesetzt.
TRACE = {}
local function T(...)
	local t = {}
	for i = 1, select('#', ...) do t[#t+1] = tostring((select(i, ...))) end
	TRACE[#TRACE+1] = table.concat(t, " | ")
end
MARK = T

NOW = 12345
SENSORS = {}
SOURCES = {}
RXID = { [0] = 5, [1] = 0 }
TIMER = 0
FILES = {}

COLOR, BOOL, VALUE, SOURCE = 1, 2, 3, 4
WHITE, BLACK, RED, GREEN, YELLOW = 0xFFFF, 0x0000, 0xF800, 0x07E0, 0xFFE0
CUSTOM_COLOR = 0x1000
SMLSIZE, MIDSIZE, DBLSIZE, XXLSIZE = 0x0200, 0x0300, 0x0400, 0x0500
INVERS, RIGHT, BLINK, PREC1, PREC2, LEFT = 0x01, 0x04, 0x08, 0x10, 0x20, 0x00
CHAR_TELEMETRY = "T:"

function getValue(n)
	local v = SENSORS[n]
	if v == nil then return 0 end
	return v
end
function getSourceIndex(n) return SOURCES[n] end
function getFieldInfo(n)
	if SENSORS[n] ~= nil then return { id = n, name = n } end
	return nil
end
function getTime() return NOW end
-- Uhrzeit läuft mit NOW mit (NOW in 10 ms), damit Log-Dateinamen sich unterscheiden
function getDateTime()
	local s = math.floor(NOW / 100)
	return { year = 2026, mon = 9, day = 24, hour = 14 + math.floor(s / 3600) % 10, min = math.floor(s / 60) % 60, sec = s % 60 }
end

model = {
	getModule = function(i) return { modelId = RXID[i] } end,
	getInfo = function() return { name = "TestModell", filename = "model01.yml" } end,
	getTimer = function(i) return { value = TIMER } end,
}

lcd = setmetatable({}, { __index = function(_, k) return function(...) T("lcd." .. k, ...) end end })
function playFile(f) T("playFile", f) end
function playNumber(...) T("playNumber", ...) end
function playTone(...) T("playTone", ...) end
local realprint = print
function print(...) T("print", ...) end

io = {
	open = function(name, mode)
		T("io.open", name, mode)
		if mode == "w" or FILES[name] == nil then FILES[name] = "" end
		return { name = name }
	end,
	write = function(f, ...)
		for i = 1, select('#', ...) do FILES[f.name] = FILES[f.name] .. tostring((select(i, ...))) end
	end,
	close = function(f) T("io.close", f.name) end,
}

function loadScript(path)
	local p = ROOT .. path:gsub("^/WIDGETS", "")
	return loadfile(p)
end

-- Widget laden und Instanz erzeugen
local LOADED = {}
function makeWidget(name, zone, optoverride)
	-- wie in EdgeTX: Skript einmal laden, create() pro Instanz
	if LOADED[name] == nil then LOADED[name] = dofile(ROOT .. "/" .. name .. "/main.lua") end
	local w = LOADED[name]
	local opts = {}
	for _, o in ipairs(w.options) do opts[o[1]] = o[3] end
	for k, v in pairs(optoverride or {}) do opts[k] = v end
	local wgt = w.create(zone, opts)
	w.update(wgt, opts)
	return w, wgt
end

function safe(f, ...)
	local ok, err = pcall(f, ...)
	if not ok then T("ERROR", (tostring(err):gsub("^.-:%d+: ", ""))) end
end
