#!/usr/bin/env bash
# Fix for: "'AgoraRtcWrapper/AgoraPIPController.h' file not found"
# when building agora_rtc_engine 6.5.x via Swift Package Manager.
#
# Root cause: the plugin's Package.swift pins the AgoraRtcWrapper binary to
# AgoraIrisRTC_iOS-4.5.2-build.1.zip, which does NOT contain AgoraPIPController.h.
# The 4.5.3-build.1 archive does (verified), so we point the URL+checksum at it.
#
# Re-run this after: deleting ~/.pub-cache, flutter pub upgrade re-downloading
# the plugin, or if the error returns.

set -euo pipefail

PLUGIN_VERSION="6.5.4"
PACKAGE_SWIFT="${HOME}/.pub-cache/hosted/pub.flutter-io.cn/agora_rtc_engine-${PLUGIN_VERSION}/ios/agora_rtc_engine/Package.swift"

OLD_URL="https://download.agora.io/sdk/release/AgoraIrisRTC_iOS-4.5.2-build.1.zip"
NEW_URL="https://download.agora.io/sdk/release/AgoraIrisRTC_iOS-4.5.3-build.1.zip"
OLD_SUM="d5daaf4ef5a773c8710ac45fb72cc72b5a7757e3d63e3d58ced38fd9368de05e"
NEW_SUM="0ec17b1658d4f149e962f16d88c23f71b97319416e6e136bf32e7a12b7bdc352"

if [[ ! -f "$PACKAGE_SWIFT" ]]; then
  echo "NOT FOUND: $PACKAGE_SWIFT"
  echo "Adjust PLUGIN_VERSION at the top of this script to match pubspec.lock."
  exit 1
fi

if grep -q "$NEW_URL" "$PACKAGE_SWIFT"; then
  echo "OK (already patched): $PACKAGE_SWIFT"
else
  cp "$PACKAGE_SWIFT" "$PACKAGE_SWIFT.bak"
  sed -i '' "s|$OLD_URL|$NEW_URL|; s|$OLD_SUM|$NEW_SUM|" "$PACKAGE_SWIFT"
  echo "PATCHED: $PACKAGE_SWIFT"
fi

echo
echo "== Clearing stale SPM artifact for agora_rtc_engine =="
rm -rf \
  "${PWD}/build/ios/SourcePackages/artifacts/agora_rtc_engine-${PLUGIN_VERSION}" \
  "${PWD}/build/ios/SourcePackages/artifacts/extract/agora_rtc_engine-${PLUGIN_VERSION}"
echo "removed."

echo
echo "Done. Now run: flutter run"
