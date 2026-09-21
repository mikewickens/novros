#!/usr/bin/env bash
# ---------------------------------------------------------------------
# Turn Mixamo FBX downloads into something the board can use.
#
#   ./bin/mixamo.sh character ~/Downloads/Megan.fbx  Megan
#       -> media/holo/Megan.glb
#
#   ./bin/mixamo.sh anims ~/Downloads/dances  Megan
#       -> media/holo/Megan.anims/*.glb, one per FBX
#
# The character and its animations share a skeleton, so the board loads
# the character once and plays any clip in its .anims folder. Download
# the character WITH SKIN; the animations can be with or without.
#
# Textures are stripped: holo mode replaces every material with the
# ghost shader, and Mixamo embeds them at full size -- it is the
# difference between 2MB and 60MB per file for something never sampled.
# ---------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"; SRC="${2:-}"; NAME="${3:-}"
BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"
[ -x "$BLENDER" ] || { echo "Blender not found at $BLENDER"; exit 1; }
[ -n "$MODE" ] && [ -n "$SRC" ] && [ -n "$NAME" ] || {
  echo "usage: $0 character <file.fbx> <Name>"; echo "       $0 anims <folder> <Name>"; exit 1; }

SCRIPT="$(mktemp -t fbx2glb).py"
cat > "$SCRIPT" <<'PY'
import bpy, sys, os
a = sys.argv[sys.argv.index("--") + 1:]
src, dst = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src, automatic_bone_orientation=True)
for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        o.scale = (0.01, 0.01, 0.01)      # Mixamo exports in centimetres
os.makedirs(os.path.dirname(dst), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB',
    export_animations=True, export_skins=True, export_apply=False,
    export_yup=True, export_materials='NONE', export_image_format='NONE')
print("WROTE", dst)
PY

conv () { "$BLENDER" --background --python "$SCRIPT" -- "$1" "$2" 2>&1 | grep -E "^WROTE|Error:" || true; }

if [ "$MODE" = "character" ]; then
  conv "$SRC" "$PWD/media/holo/$NAME.glb"
elif [ "$MODE" = "anims" ]; then
  n=0
  for f in "$SRC"/*.fbx; do
    [ -e "$f" ] || { echo "no .fbx files in $SRC"; exit 1; }
    base="$(basename "$f" .fbx)"
    conv "$f" "$PWD/media/holo/$NAME.anims/$base.glb"
    n=$((n+1))
  done
  echo "$n animation(s) -> media/holo/$NAME.anims/"
else
  echo "unknown mode: $MODE (expected 'character' or 'anims')"; exit 1
fi
rm -f "$SCRIPT"
echo "Press R on the board to pick it up."
