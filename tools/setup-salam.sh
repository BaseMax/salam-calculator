#!/bin/sh
set -eu

version=${SALAM_VERSION:?}
work=${1:?usage: setup-salam.sh <folder> <platform>}
platform=${2:?usage: setup-salam.sh <folder> <platform>}
name="salam-$version-$platform.tar.gz"

mkdir -p "$work/compiler"
cd "$work"
gh release download "v$version" --repo SalamLang/Salam --clobber \
    -p "$name" -p "$name.sha256"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$name.sha256"
else
    shasum -a 256 -c "$name.sha256"
fi
tar -xzf "$name" -C compiler
salam=$(find "$work/compiler" -type f -name salam | head -n 1)
[ -n "$salam" ] || { echo "No salam program in $name" >&2; exit 1; }
chmod +x "$salam"
echo "SALAM=$salam" >>"$GITHUB_ENV"
