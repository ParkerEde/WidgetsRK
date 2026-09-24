"""Prüft die RK-Lib-Kontrolle der Widgets: Lib fehlt, Lib-Version passt nicht, Lib passt.

Getestet werden alle RKxx-Widgets, die die RK-Lib laden (oder die als Argumente genannten).
Erwartet wird bei einem Lib-Fehler: roter Hinweis statt Werten, kein Script-Fehler,
background() tut nichts.

Aufruf aus dem Repo-Ordner (Einrichtung siehe harness.py):
    %TEMP%\\rk-luatest\\Scripts\\python test\\libcheck.py [RK05 ...]
"""
import sys, re, shutil, pathlib, tempfile
from lupa.lua52 import LuaRuntime

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.stdout.reconfigure(encoding="utf-8")

RED = "63488"  # Wert von RED in mock.lua


def run(root, name):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ROOT = str(root).replace("\\", "/")
    lua.execute((HERE / "mock.lua").read_text(encoding="utf-8"))
    lua.execute(f'''
        local w, full = makeWidget("{name}", {{x=0,y=0,w=392,h=172}})
        local _, top = makeWidget("{name}", {{x=0,y=0,w=70,h=36}})
        MARK("LOADED")
        for s = 1, 3 do
            NOW = NOW + 100
            MARK("REFRESH_FULL"); safe(w.refresh, full)
            MARK("REFRESH_TOP");  safe(w.refresh, top)
            MARK("BACKGROUND");   safe(w.background, full)
        end
    ''')
    t = lua.globals().TRACE
    return [t[i] for i in range(1, len(t) + 1)]


def calls_after(trace, marker):
    """Aufrufe zwischen marker und dem nächsten Marker, für den ersten Durchlauf."""
    i = trace.index(marker) + 1
    out = []
    while i < len(trace) and trace[i] not in ("REFRESH_FULL", "REFRESH_TOP", "BACKGROUND"):
        out.append(trace[i]); i += 1
    return out


def prepare(tmp, case):
    root = pathlib.Path(tmp) / case
    for d in REPO.iterdir():
        if d.is_dir() and (d.name.startswith("RK")):
            shutil.copytree(d, root / d.name)
    lib = root / "RK-Lib" / "RK-Lib.lua"
    if case == "fehlt":
        shutil.rmtree(root / "RK-Lib")
    elif case == "falsch":
        text = lib.read_bytes().decode("utf-8")
        text = re.sub(r'lib\.version = "[^"]*"', 'lib.version = "0.0.0"', text)
        lib.write_bytes(text.encode("utf-8"))
    return root


def check(name):
    src = (REPO / name / "main.lua").read_text(encoding="utf-8")
    version = re.search(r'local RKWidgetVersion = "([^"]+)"', src).group(1)
    expected = {
        "fehlt": f"{name}: RK-Lib fehlt",
        "falsch": f"{name}: RK-Lib V0.0.0 passt nicht zu V{version}",
    }
    failures = []
    with tempfile.TemporaryDirectory() as tmp:
        for case in ("fehlt", "falsch", "ok"):
            trace = run(prepare(tmp, case), name)
            errs = [l for l in trace if l.startswith("ERROR")]
            if errs:
                failures.append(f"{case}: Script-Fehler {sorted(set(errs))}")
            full = calls_after(trace, "REFRESH_FULL")
            top = calls_after(trace, "REFRESH_TOP")
            bg = calls_after(trace, "BACKGROUND")
            hint = [l for l in trace if "RK-Lib" in l and l.startswith("lcd.drawText")]
            if case == "ok":
                if hint:
                    failures.append(f"ok: unerwarteter Lib-Hinweis {hint[0]}")
                continue
            want_full = ["lcd.setColor | 4096 | " + RED, f"lcd.drawText | 0 | 0 | {expected[case]} | 4608"]
            want_top = ["lcd.setColor | 4096 | " + RED, "lcd.drawText | 0 | 0 | RK-Lib Fehler | 4608"]
            if full != want_full:
                failures.append(f"{case}: Vollbild zeigt {full}")
            if top != want_top:
                failures.append(f"{case}: Top-Bar zeigt {top}")
            if bg:
                failures.append(f"{case}: background() tut etwas: {bg}")
    return failures


def main():
    names = sys.argv[1:] or sorted(
        d.name for d in REPO.glob("RK0*")
        if "RK-Lib" in (d / "main.lua").read_text(encoding="utf-8"))
    ok = True
    for name in names:
        failures = check(name)
        print(f"{name}: {'OK' if not failures else 'FEHLER'}")
        for f in failures:
            print("   ", f)
        ok = ok and not failures
    print("ERGEBNIS:", "OK" if ok else "FEHLER")
    sys.exit(0 if ok else 1)


main()
