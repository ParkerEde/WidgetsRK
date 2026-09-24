"""Vergleichstest: Widget-Stand aus einem Git-Ref (Standard: main) gegen das Arbeitsverzeichnis.

Beide Fassungen laufen in Lua 5.2 mit nachgebildeter EdgeTX-API (mock.lua) und demselben
Szenario. Verglichen werden alle aufgezeichneten lcd-/play-/print-Aufrufe und die
geschriebenen Log-Dateien.

Einrichtung (einmalig, außerhalb des Repos):
    python -m venv %TEMP%\\rk-luatest
    %TEMP%\\rk-luatest\\Scripts\\python -m pip install lupa

Aufruf aus dem Repo-Ordner:
    %TEMP%\\rk-luatest\\Scripts\\python test\\harness.py test\\scen_rk05.lua [git-ref]
"""
import sys, difflib, pathlib, subprocess, tarfile, tempfile, io
from lupa.lua52 import LuaRuntime

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
sys.stdout.reconfigure(encoding="utf-8")


def extract_ref(ref, target):
    data = subprocess.run(["git", "-C", str(REPO), "archive", "--format=tar", ref],
                          check=True, capture_output=True).stdout
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        tar.extractall(target, filter="data")


def run(root, scenario):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().ROOT = str(root).replace("\\", "/")
    lua.execute((HERE / "mock.lua").read_text(encoding="utf-8"))
    lua.execute(pathlib.Path(scenario).read_text(encoding="utf-8"))
    g = lua.globals()
    trace = [g.TRACE[i] for i in range(1, len(g.TRACE) + 1)]
    files = {k: v for k, v in g.FILES.items()}
    return trace, files


def main():
    scenario = sys.argv[1]
    ref = sys.argv[2] if len(sys.argv) > 2 else "main"
    with tempfile.TemporaryDirectory() as old:
        extract_ref(ref, old)
        t_old, f_old = run(old, scenario)
    t_new, f_new = run(REPO, scenario)

    print(f"Trace: {ref} {len(t_old)} Einträge, Arbeitsverzeichnis {len(t_new)} Einträge")
    ok = True
    if t_old != t_new:
        ok = False
        diff = list(difflib.unified_diff(t_old, t_new, ref, "neu", lineterm="", n=2))
        print("\n".join(diff[:80]))
        if len(diff) > 80:
            print(f"... {len(diff) - 80} weitere Diff-Zeilen")
    for name in sorted(set(f_old) | set(f_new)):
        if f_old.get(name) != f_new.get(name):
            ok = False
            print(f"Datei {name} unterschiedlich:")
            print("\n".join(difflib.unified_diff((f_old.get(name) or "").splitlines(),
                                                 (f_new.get(name) or "").splitlines(),
                                                 ref, "neu", lineterm="")))
    errs = sorted(set(l for l in t_old + t_new if l.startswith("ERROR")))
    if errs:
        print("Fehlermeldungen im Lauf:", errs)
    print("ERGEBNIS:", "IDENTISCH" if ok else "UNTERSCHIEDLICH")
    sys.exit(0 if ok else 1)


main()
