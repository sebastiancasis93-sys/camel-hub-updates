#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, sys

VERSION = "1.0.1"
ROOT = Path(__file__).resolve().parent
RELEASE = ROOT / "release"
CORE_LIST = ROOT / "CORE_FILES.txt"

if len(sys.argv) != 2:
    print("Uso:")
    print("  python build_release.py https://TU-HOST")
    print("")
    print("Ejemplo GitHub raw:")
    print("  python build_release.py https://raw.githubusercontent.com/USUARIO/REPO/main")
    raise SystemExit(2)

base = sys.argv[1].rstrip("/")
if not base.startswith("https://"):
    raise SystemExit("La BASE_URL debe comenzar con https://")

allowed = [
    line.strip()
    for line in CORE_LIST.read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]

files = []
for rel in allowed:
    p = RELEASE / rel
    if not p.is_file():
        raise SystemExit(f"Falta archivo del core: {rel}")

    data = p.read_bytes()
    files.append({
        "path": rel,
        "url": f"{base}/release/{rel}",
        "sha256": hashlib.sha256(data).hexdigest(),
        "sha1": hashlib.sha1(data).hexdigest(),
    })

manifest = {
    "product": "Camel Hub",
    "channel": "stable",
    "version": VERSION,
    "summary": [
        "Core comun inicial generado desde los cinco bots actuales.",
        "Solo actualiza codigo comun validado como identico entre personajes."
    ],
    "files": files
}

out = ROOT / "manifest.json"
out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

print(f"Creado: {out}")
print(f"Version: {VERSION}")
print(f"Archivos: {len(files)}")
print(f"Manifest URL: {base}/manifest.json")
