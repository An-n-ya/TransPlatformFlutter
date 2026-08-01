#!/usr/bin/env bash
# Fix for: "Namespace 'io.agora.rtc' is used in multiple modules and/or libraries"
# caused by legacy Agora AARs (iris-rtc, agora-special-full) both declaring
# package="io.agora.rtc" in their manifests. AGP 8.4+ enforces unique namespaces
# during manifest merging.
#
# This patches the AARs inside the local Gradle cache (~/.gradle) to give
# iris-rtc the namespace "io.agora.iris" (its Java classes already live under
# io.agora.iris.*, so this is safe) and clears the stale transform cache so the
# patched manifests get re-read.
#
# Re-run this after: flutter clean, deleting ~/.gradle, or if the error returns.

set -euo pipefail

GRADLE_CACHE="${HOME}/.gradle/caches"
PATCHED=0

patch_aar_manifest() {
  local aar="$1"
  local from="$2"
  local to="$3"
  [[ -f "$aar" ]] || { echo "SKIP: not found: $aar"; return; }

  local work; work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN
  cp "$aar" "$work/orig.aar"
  (cd "$work" && unzip -oq orig.aar -d contents)

  local manifest="$work/contents/AndroidManifest.xml"
  if ! grep -q "$from" "$manifest"; then
    echo "OK (already patched): $(basename "$aar")"
    return
  fi

  sed -i "s/$from/$to/" "$manifest"
  (cd "$work/contents" && zip -qr ../patched.aar .)
  cp "$work/patched.aar" "$aar"
  echo "PATCHED: $aar"
  PATCHED=1
}

echo "== Patching Agora AAR manifests in Gradle cache =="

# Patch every iris-rtc version found in the cache (agora_rtc_engine 6.5.x uses
# iris-rtc 4.5.3-build.1, 6.6.x uses 4.6.2-build.1, etc.). All of them declare
# package="io.agora.rtc" and conflict with agora-special-full.
while IFS= read -r aar; do
  patch_aar_manifest "$aar" 'package="io.agora.rtc"' 'package="io.agora.iris"'
done < <(find "$GRADLE_CACHE/modules-2/files-2.1/io.agora.rtc/iris-rtc" -name 'iris-rtc-*.aar' 2>/dev/null | sort)

# agora-special-full keeps package="io.agora.rtc" (now unique after iris-rtc is renamed)

echo
echo "== Clearing transform cache (forces AAR manifests to be re-read) =="
# The whole transforms dir must be cleared: its index still points at the
# pre-patch outputs otherwise, causing FileNotFoundException at manifest merge.
for dir in "$GRADLE_CACHE"/*/transforms; do
  [[ -d "$dir" ]] && rm -rf "$dir" && echo "removed: $dir"
done

echo
if [[ "$PATCHED" -eq 1 ]]; then
  echo "Done. Now run: flutter run"
else
  echo "No changes needed."
fi
