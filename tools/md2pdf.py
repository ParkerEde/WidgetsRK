"""Erzeugt aus der Markdown-Doku ein PDF (Markdown -> HTML -> PDF über Edge/Chrome headless).

Die Markdown-Datei ist die einzige Quelle der Doku; das PDF wird nur für Releases und
für Nutzer ohne GitHub erzeugt.

Einrichtung (einmalig, außerhalb des Repos, dieselbe Umgebung wie für test/):
    %TEMP%\\rk-luatest\\Scripts\\python -m pip install markdown

Aufruf aus dem Repo-Ordner:
    %TEMP%\\rk-luatest\\Scripts\\python tools\\md2pdf.py "docs\\RK01-05 Widgets Doku 1.1.x.md" [ziel.pdf] [--version 1.2.0]
Ohne Ziel wird das PDF neben die Markdown-Datei gelegt.
"""
import sys, pathlib, subprocess, tempfile, shutil, datetime
import markdown

BROWSER = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
]

CSS = """
@page { size: A4; margin: 18mm 16mm 18mm 16mm; }
body { font-family: "Segoe UI", Arial, sans-serif; font-size: 10.5pt; line-height: 1.45; color: #111; }
h1 { font-size: 20pt; border-bottom: 2px solid #333; padding-bottom: 4px; }
h2 { font-size: 14pt; margin-top: 1.4em; border-bottom: 1px solid #999; padding-bottom: 2px; page-break-after: avoid; }
h3 { font-size: 11.5pt; margin-top: 1.1em; page-break-after: avoid; }
img { max-width: 100%; width: 480px; page-break-inside: avoid; border: 1px solid #ccc; }
p:has(> img) { page-break-inside: avoid; }
table { border-collapse: collapse; margin: 0.6em 0; }
th, td { border: 1px solid #999; padding: 3px 6px; vertical-align: top; }
code { font-family: Consolas, monospace; font-size: 9.5pt; }
blockquote { color: #444; border-left: 3px solid #bbb; margin-left: 0; padding-left: 10px; }
.fuss { margin-top: 2em; font-size: 8.5pt; color: #666; }
"""


def main():
    args = sys.argv[1:]
    version = None
    if "--version" in args:
        i = args.index("--version")
        version = args[i + 1]
        del args[i:i + 2]
    src = pathlib.Path(args[0]).resolve()
    dst = pathlib.Path(args[1]).resolve() if len(args) > 1 else src.with_suffix(".pdf")
    browser = next((b for b in BROWSER if pathlib.Path(b).exists()), None)
    if browser is None:
        sys.exit("Kein Edge/Chrome gefunden.")

    text = src.read_text(encoding="utf-8")
    # Hinweiszeile für GitHub ("Diese Datei ist die Quelle ...") gehört nicht ins PDF
    text = "\n".join(l for l in text.splitlines() if not (l.startswith(">") and "md2pdf" in l))
    body = markdown.markdown(text, extensions=["tables", "sane_lists"])
    fuss = f"Stand: {datetime.date.today():%d.%m.%Y}" + (f" · Version {version}" if version else "")
    html = (f'<!DOCTYPE html><html lang="de"><head><meta charset="utf-8"><title>{src.stem}</title>'
            f'<base href="{src.parent.as_uri()}/"><style>{CSS}</style></head>'
            f'<body>{body}<p class="fuss">{fuss}</p></body></html>')

    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / "doku.html"
        page.write_text(html, encoding="utf-8")
        out = pathlib.Path(tmp) / "doku.pdf"
        subprocess.run([browser, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                        f"--print-to-pdf={out}", page.as_uri()],
                       check=True, capture_output=True, timeout=120)
        shutil.copyfile(out, dst)
    print(f"PDF erzeugt: {dst} ({dst.stat().st_size // 1024} KB)")


main()
