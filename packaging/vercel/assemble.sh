#!/usr/bin/env bash
# WordNext fork: assemble the site Vercel serves.
#
#   dist/web   (Trunk output: the app)        ->  dist/site/app/
#   packaging/vercel/site/   (landing, PWA)   ->  dist/site/
#   assets/app-icon          (icons)          ->  dist/site/ and dist/site/app/
#
# Kept apart from build.sh so it can run (and be tested) without Rust or Trunk.
# Usage: packaging/vercel/assemble.sh   (from anywhere; expects dist/web to exist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/dist/web"
SITE="$ROOT/dist/site"
ICONS="$ROOT/assets/app-icon"

[ -f "$APP/index.html" ] || { echo "error: $APP/index.html missing; build the app first" >&2; exit 1; }

rm -rf "$SITE"
mkdir -p "$SITE/app"
cp -R "$ROOT/packaging/vercel/site/." "$SITE/"
cp -R "$APP/." "$SITE/app/"

# Icons come from assets/app-icon (the app icon), so there is
# a single copy to keep in step.
# The app folder gets its own copy because the app's URLs are relative and it must work on its own.
for dir in "$SITE" "$SITE/app"; do
  cp "$ICONS/filmcraft.svg" "$dir/icon.svg"
  cp "$ICONS/hicolor/256x256/apps/tech.wordnext.films.png" "$dir/icon-256.png"
  cp "$ICONS/hicolor/512x512/apps/tech.wordnext.films.png" "$dir/icon-512.png"
done

# The app's URLs must stay relative: it is served from /app/ and, unchanged, from any other path.
if grep -Eq '(src|href)="/[^/]' "$SITE/app/index.html"; then
  echo "error: dist/site/app/index.html has root-absolute URLs" >&2
  exit 1
fi

echo "assembled $SITE"
( cd "$SITE" && find . -maxdepth 2 -not -name '*.wasm' -not -name '*.js' | sort | head -40 )
