#!/bin/bash
set -euo pipefail
APP="$1"
OUT="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
VOLUME="ShineGram"
APPLICATIONS_NAME=$(printf '\xe2\x81\xa0')

mkdir -p "$WORK/stage/.background"
ditto "$APP" "$WORK/stage/ShineGram.app"
ln -s /Applications "$WORK/stage/$APPLICATIONS_NAME"
cp "$HERE/background.tiff" "$WORK/stage/.background/background.tiff"
cp "$HERE/VolumeIcon.icns" "$WORK/stage/.VolumeIcon.icns"
cp "$HERE/DS_Store" "$WORK/stage/.DS_Store"

SIZE_MB=$(( $(du -sm "$WORK/stage" | cut -f1) + 60 ))
hdiutil create -srcfolder "$WORK/stage" -volname "$VOLUME" -fs HFS+ -format UDRW -size "${SIZE_MB}m" "$WORK/rw.dmg" -quiet
DEVICE=$(hdiutil attach "$WORK/rw.dmg" -readwrite -noverify -noautoopen | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT="/Volumes/$VOLUME"
cp "$HERE/VolumeIcon.icns" "$MOUNT/.VolumeIcon.icns"
cp "$HERE/DS_Store" "$MOUNT/.DS_Store"
SetFile -a C "$MOUNT"
sync
hdiutil detach "$DEVICE" -quiet || hdiutil detach "$DEVICE" -force -quiet

rm -f "$OUT"
hdiutil convert "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$OUT" -quiet
swift "$HERE/set-file-icon.swift" "$HERE/VolumeIcon.icns" "$OUT" || true
hdiutil verify "$OUT" -quiet
rm -rf "$WORK"
echo "$OUT"
