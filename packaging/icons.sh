#!/usr/bin/env bash
# Regenerate every derived app icon from assets/app-icon/filmcraft.svg (the canonical artwork; a
# 512-unit full-bleed tile with rx=112). filmcraft-small.svg is a lighter trace of the same drawing
# and is copied, not generated.
#
# Needs: resvg (brew install resvg / cargo install resvg). On macOS, iconutil also writes the
# .icns. The outputs are committed, so builds and packaging never need these tools.
#
#   packaging/icons.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/assets/app-icon"
SVG="$DIR/filmcraft.svg"
APP_ID="tech.wordnext.films"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v resvg >/dev/null || { echo "error: resvg not found (brew install resvg)" >&2; exit 1; }

# macOS icons follow Apple's grid: the tile body is 824 of 1024 px with a transparent margin, so
# the Dock shows it at the same size as other apps. 512 * 1024 / 824 = 636.27 units, margin 62.14.
MAC="$TMP/mac.svg"
sed 's/viewBox="0 0 512 512"/viewBox="-62.14 -62.14 636.27 636.27"/' "$SVG" >"$MAC"
grep -q 'viewBox="-62.14' "$MAC" || { echo "error: unexpected viewBox in $SVG" >&2; exit 1; }

render() { resvg -w "$2" -h "$2" "$1" "$3" </dev/null; }

render "$SVG" 1024 "$DIR/filmcraft-1024.png"
# Runtime window/Dock icon on macOS (apps/filmcraft/src/main.rs embeds it).
render "$MAC" 512 "$DIR/filmcraft-macos-512.png"

# Linux hicolor theme. Windows and Linux use the full-bleed tile.
for s in 16 24 32 48 64 128 256 512; do
  mkdir -p "$DIR/hicolor/${s}x${s}/apps"
  render "$SVG" "$s" "$DIR/hicolor/${s}x${s}/apps/$APP_ID.png"
done
mkdir -p "$DIR/hicolor/scalable/apps"
cp "$DIR/filmcraft-small.svg" "$DIR/hicolor/scalable/apps/$APP_ID.svg"

# Web app favicon and loading image.
render "$SVG" 128 "$ROOT/apps/filmcraft-web/web/favicon.png"

# Windows .ico.
ICO_PNGS=()
for s in 16 20 24 32 40 48 64 128 256; do
  render "$SVG" "$s" "$TMP/ico-$s.png"
  ICO_PNGS+=("$TMP/ico-$s.png")
done
if command -v cargo >/dev/null && [ -z "${ICONS_PYTHON:-}" ]; then
  (cd "$ROOT" && cargo run -q -p xtask -- ico "$DIR/filmcraft.ico" "${ICO_PNGS[@]}")
else
  # PNG-compressed .ico written by python3 (set ICONS_PYTHON=1 to force it).
  python3 - "$DIR/filmcraft.ico" "${ICO_PNGS[@]}" <<'PY'
import struct, sys
out, pngs = sys.argv[1], sys.argv[2:]
blobs = [open(p, "rb").read() for p in pngs]
head = struct.pack("<HHH", 0, 1, len(blobs))
off = 6 + 16 * len(blobs)
ents = b""
for b in blobs:
    w, h = struct.unpack(">II", b[16:24])
    ents += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(b), off)
    off += len(b)
open(out, "wb").write(head + ents + b"".join(blobs))
PY
fi

# macOS .icns.
if command -v iconutil >/dev/null; then
  SET="$TMP/filmcraft.iconset"
  mkdir -p "$SET"
  for s in 16 32 128 256 512; do
    render "$MAC" "$s" "$SET/icon_${s}x${s}.png"
    render "$MAC" $((s * 2)) "$SET/icon_${s}x${s}@2x.png"
  done
  iconutil -c icns -o "$DIR/filmcraft.icns" "$SET"
else
  # .icns written by python3: PNG-compressed entries (ic07..ic10, ic11..ic14).
  python3 - "$DIR/filmcraft.icns" "$MAC" <<'PY'
import struct, subprocess, sys, tempfile, os
out, svg = sys.argv[1], sys.argv[2]
kinds = [(b"ic07", 128), (b"ic08", 256), (b"ic09", 512), (b"ic10", 1024), (b"ic11", 32), (b"ic12", 64), (b"ic13", 256), (b"ic14", 512)]
body = b""
for tag, px in kinds:
    with tempfile.TemporaryDirectory() as d:
        f = os.path.join(d, "i.png")
        subprocess.run(["resvg", "-w", str(px), "-h", str(px), svg, f], check=True, stdin=subprocess.DEVNULL)
        data = open(f, "rb").read()
    body += tag + struct.pack(">I", len(data) + 8) + data
open(out, "wb").write(b"icns" + struct.pack(">I", len(body) + 8) + body)
PY
fi
echo "icons written to $DIR"
