#!/usr/bin/env bash
set -euo pipefail
GODOT_VERSION="4.7.2"
BASE="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
WORK="${RUNNER_TEMP:-/tmp}/orbforge-godot-${GODOT_VERSION}"
mkdir -p "$WORK"
CURL_FLAGS=(--fail --location --show-error --silent --retry 4 --retry-delay 3)
curl "${CURL_FLAGS[@]}" "${BASE}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o "$WORK/godot.zip"
curl "${CURL_FLAGS[@]}" "${BASE}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$WORK/templates.tpz"
unzip -q "$WORK/godot.zip" -d "$WORK"
mkdir -p "$HOME/.local/bin"
install -m 755 "$WORK/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$HOME/.local/bin/godot"
export PATH="$HOME/.local/bin:$PATH"
if [ -n "${GITHUB_PATH:-}" ]; then echo "$HOME/.local/bin" >> "$GITHUB_PATH"; fi
mkdir -p "$WORK/unpacked"
unzip -q "$WORK/templates.tpz" -d "$WORK/unpacked"
TEMPLATE_TARGET="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p "$(dirname "$TEMPLATE_TARGET")"
cp -a "$WORK/unpacked/templates" "$TEMPLATE_TARGET"
test -s "$TEMPLATE_TARGET/android_debug.apk"
test -s "$TEMPLATE_TARGET/android_release.apk"
test -s "$TEMPLATE_TARGET/android_source.zip"
godot --headless --version
printf 'Godot %s editor + matching export templates installed.\n' "$GODOT_VERSION"
