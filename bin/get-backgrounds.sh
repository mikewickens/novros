#!/usr/bin/env bash
# ---------------------------------------------------------------------
# Fill media/backgrounds from the wallpapers already on THIS machine.
#
# The repo ships no wallpapers. Apple's desktop pictures are Apple's, and
# a fork has no licence to redistribute them -- but every Mac already has
# them, so there is nothing to redistribute: this converts your own copies
# into something the board can use.
#
# macOS ships them as HEIC at up to 6K. Chrome cannot decode HEIC, so they
# are converted to JPEG with sips, which is built in. Nothing to install.
#
#   ./bin/get-backgrounds.sh            convert at 3840 wide
#   ./bin/get-backgrounds.sh 2560       or pick your own width
# ---------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

WIDTH="${1:-3840}"
OUT="media/backgrounds"
SRC="/System/Library/Desktop Pictures"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script reads macOS's own wallpapers, so it only runs on a Mac."
  echo "On any system you can drop your own images into $OUT instead."
  exit 1
fi
command -v sips >/dev/null || { echo "sips not found (it ships with macOS)"; exit 1; }
[ -d "$SRC" ] || { echo "No desktop pictures at $SRC on this machine."; exit 1; }

mkdir -p "$OUT"
echo "Converting from $SRC at ${WIDTH}px wide..."
n=0; skipped=0
while IFS= read -r f; do
  base="$(basename "$f" .heic)"
  dest="$OUT/${base}.jpg"
  # Several wallpapers share a basename across folders -- there is more
  # than one Blue.heic and more than one Yellow.heic. Taking the first
  # and calling the rest "already there" silently loses them, so a
  # collision takes the parent folder's name to tell them apart.
  if [ -e "$dest" ]; then
    parent="$(basename "$(dirname "$f")")"
    dest="$OUT/${base} (${parent}).jpg"
  fi
  if [ -e "$dest" ]; then skipped=$((skipped+1)); continue; fi
  if sips -s format jpeg -s formatOptions 88 -Z "$WIDTH" "$f" --out "$dest" >/dev/null 2>&1; then
    n=$((n+1)); printf "\r  %d converted" "$n"
  fi
done < <(find "$SRC" -name "*.heic" -not -path "*Thumbnail*" 2>/dev/null)

echo
echo "Done: $n new, $skipped already there."
echo "Total in $OUT: $(ls -1 "$OUT" 2>/dev/null | grep -icE '\.(jpg|jpeg|png|webp)$' || echo 0) images."
echo "Press R on the board to pick them up, then Settings -> Background."
