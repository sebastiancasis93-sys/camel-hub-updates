#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, sys, zlib

VERSION = "1.0.1"
ROOT = Path(__file__).resolve().parent
RELEASE = ROOT / "release"
CORE_LIST = ROOT / "CORE_FILES.txt"

if len(sys.argv) != 2:
    print("Uso: python build_release.py https://TU-HOST")
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
    if rel == "vBot/CamelHubUpdater.lua":
        continue

    p = RELEASE / rel
    if not p.is_file():
        raise SystemExit(f"Falta archivo del core: {rel}")

    data = p.read_bytes()
    text = data.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")
    norm = text.encode("utf-8")

    files.append({
        "path": rel,
        "url": f"{base}/release/{rel}",
        "normalizedSize": len(norm),
        "adler32": f"{zlib.adler32(norm) & 0xffffffff:08x}",
        "sha256": hashlib.sha256(data).hexdigest(),
    })

manifest = {
    "product": "Camel Hub",
    "channel": "stable",
    "version": VERSION,
    "updaterProtocol": "normalized-adler32-v2",
    "summary": [
        "Core Camel Hub.",
        "Checksums normalizados LF/CRLF.",
        "Updater excluido del auto-update."
    ],
    "files": files
}

out = ROOT / "manifest.json"
out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"Creado: {out}")
print(f"Version: {VERSION}")
print(f"Archivos: {len(files)}")
