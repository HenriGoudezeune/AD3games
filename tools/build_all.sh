#!/usr/bin/env bash
# Bouwt de AD3 Speelhal voor Windows, Linux en macOS in build/ (staat in .gitignore).
# Vereist Godot 4.7.2 + de export-templates 4.7.2. Gebruik: tools/build_all.sh [pad-naar-godot]
set -euo pipefail
G="${1:-godot}"
cd "$(dirname "$0")/.."
mkdir -p build/windows build/linux build/macos
"$G" --headless --path . --import
"$G" --headless --path . --export-release "Windows" "build/windows/AD3 Speelhal.exe"
"$G" --headless --path . --export-release "Linux" "build/linux/AD3_Speelhal.x86_64"
"$G" --headless --path . --export-release "macOS" "build/macos/AD3_Speelhal_macOS.zip"
echo "Klaar: build/"
