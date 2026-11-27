#!/bin/sh
set -eu

app=${1:?usage: ios-smoke.sh <App.app> <screenshot.png>}
shot=${2:?usage: ios-smoke.sh <App.app> <screenshot.png>}
id=ir.salamlang.calculator

device=$(xcrun simctl list devices available | grep -m 1 "iPhone" |
    sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$device" ] || { echo "No iPhone simulator" >&2; exit 1; }
xcrun simctl boot "$device"
trap 'xcrun simctl shutdown "$device"' EXIT
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" "$id" -salam-script "wait 3000;tap 60,500"
sleep 15
xcrun simctl spawn "$device" launchctl list | grep -q "$id" ||
    { echo "The app is no longer running" >&2; exit 1; }
xcrun simctl io "$device" screenshot "$shot"
echo "The app started"
