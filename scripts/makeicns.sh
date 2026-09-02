#!/bin/bash
# 1024x1024 PNG 하나를 Resources/AppIcon.icns 로 변환한다.
#   ./scripts/makeicns.sh Resources/icon-1024.png
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:-Resources/icon-1024.png}"
[ -f "$SRC" ] || { echo "원본을 찾을 수 없음: $SRC" >&2; exit 1; }

TMP="$(mktemp -d)"
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"

for spec in 16:16x16 32:16x16@2x 32:32x32 64:32x32@2x \
            128:128x128 256:128x128@2x 256:256x256 512:256x256@2x \
            512:512x512 1024:512x512@2x; do
  px="${spec%%:*}"; name="${spec##*:}"
  sips -z "$px" "$px" "$SRC" --out "$SET/icon_${name}.png" >/dev/null
done

mkdir -p Resources
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -rf "$TMP"
echo "생성 완료: Resources/AppIcon.icns"
