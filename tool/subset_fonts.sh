#!/usr/bin/env bash
# Regenerates the JetBrains Mono subsets the site ships.
#
# Two formats, because the two halves of the site read fonts differently:
#   assets/fonts/*.ttf    the Flutter app — CanvasKit cannot decode woff2
#   web/fonts/*.woff2     index.html and resume.html, via @font-face
#
# Usage:  pip install fonttools brotli && tool/subset_fonts.sh
set -euo pipefail

VERSION=2.304
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Latin, plus the punctuation this page actually sets: · — → and friends.
# Anything outside this falls back to a system font, so widen it before adding
# copy that needs a glyph it does not cover.
UNICODES="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC"
UNICODES="$UNICODES,U+0304,U+0308,U+0329,U+2000-206F,U+2074,U+20AC,U+2122"
UNICODES="$UNICODES,U+2190-2199,U+2212,U+2215,U+25A0-25A1,U+FEFF,U+FFFD"

curl -sSL -o "$WORK/jbm.zip" \
  "https://github.com/JetBrains/JetBrainsMono/releases/download/v$VERSION/JetBrainsMono-$VERSION.zip"
unzip -q -o "$WORK/jbm.zip" -d "$WORK/jbm"

for weight in Regular Medium; do
  src="$WORK/jbm/fonts/ttf/JetBrainsMono-$weight.ttf"

  # --layout-features='' drops the ligature tables. This is a portfolio, not an
  # editor: `->` should render as two glyphs, and the arrow that is meant to be
  # an arrow is a real U+2192.
  common=(--unicodes="$UNICODES" --layout-features='' --no-hinting
          --drop-tables+=DSIG)

  pyftsubset "$src" "${common[@]}" \
    --output-file="$ROOT/assets/fonts/JetBrainsMono-$weight.ttf"
  pyftsubset "$src" "${common[@]}" --flavor=woff2 \
    --output-file="$ROOT/web/fonts/JetBrainsMono-$weight.woff2"
done

cp "$WORK/jbm/OFL.txt" "$ROOT/assets/fonts/OFL.txt"
cp "$WORK/jbm/OFL.txt" "$ROOT/web/fonts/OFL.txt"

ls -l "$ROOT/assets/fonts" "$ROOT/web/fonts"
