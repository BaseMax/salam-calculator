#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
salam=${SALAM:-salam}
work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT
cd "$root"

"$salam" check . --ui=native

"$salam" build tests/engine.salam -o "$work/engine"
"$work/engine" >"$work/engine.out"
diff -u tests/engine.out "$work/engine.out"
echo "The calculator logic passed"

"$salam" build . --ui=native -o "$work/app"
mkdir "$work/data"
SALAM_CALCULATOR_HOME="$work/data" SALAM_WINDOW_BACKEND=headless \
    SALAM_UI_SCRIPT="$root/tests/ui.script" "$work/app" >"$work/ui.log" 2>&1 ||
    { cat "$work/ui.log" >&2; exit 1; }
if grep "ui script:" "$work/ui.log" >&2; then
    exit 1
fi
diff -u tests/ui.history "$work/data/history.tsv"
echo "The window flow passed"
