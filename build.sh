#!/bin/bash
set -eu
cd "$(dirname "$0")"
dir="build/TickerBar.app/Contents"
mkdir -p "$dir/MacOS" "$dir/Resources"
swiftc -O main.swift HoldShortcut.swift -o "$dir/MacOS/TickerBar"
cp "$(command -v node)" feed.js "$dir/Resources/"
cp -R node_modules "$dir/Resources/"
cat > "$dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>local.tickerbar.app</string><key>CFBundleExecutable</key><string>TickerBar</string><key>CFBundleName</key><string>TickerBar</string><key>CFBundlePackageType</key><string>APPL</string><key>LSUIElement</key><true/></dict></plist>
PLIST
codesign --force --sign - "build/TickerBar.app"
