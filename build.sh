#!/bin/sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
salam=${SALAM:-salam}
version=${VERSION:-$(sed -n 's/^version = "\(.*\)"/\1/p' "$here/salam.toml")}
out=${OUT:-$here/dist}
name="Salam Calculator"
slug=salam-calculator
file="SalamCalculator-$version"

case $(uname -s) in
Darwin) host=macos ;;
Linux) host=linux ;;
*) host=windows ;;
esac
platform=${1:-$host}

build_number() {
    echo "$version" | awk -F. '{ n = $1 * 10000 + $2 * 100 + $3; print (n > 0 ? n : 1) }'
}

macos_icon() {
    set_dir="$1/icon.iconset"
    mkdir -p "$set_dir"
    for size in 16 32 128 256 512; do
        sips -z $size $size "$here/assets/icon.png" \
            --out "$set_dir/icon_${size}x${size}.png" >/dev/null
        double=$((size * 2))
        sips -z $double $double "$here/assets/icon.png" \
            --out "$set_dir/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$set_dir" -o "$2"
}

build_macos() {
    arch=$(uname -m)
    stage="$out/macos"
    app="$stage/$name.app"
    rm -rf "${stage:?}"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    minimum=${MACOSX_DEPLOYMENT_TARGET:-}
    "$salam" build "$here" --ui=native ${minimum:+"--target=$arch-apple-macosx$minimum"} \
        -o "$app/Contents/MacOS/$slug"
    work=$(mktemp -d)
    macos_icon "$work" "$app/Contents/Resources/icon.icns"
    rm -rf "${work:?}"
    cat >"$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$slug</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>ir.salamlang.calculator</string>
    <key>CFBundleName</key>
    <string>$name</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$(build_number)</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST
    codesign --force --sign - "$app"
    cp "$here/LICENSE" "$stage/LICENSE.txt"
    ln -s /Applications "$stage/Applications"
    hdiutil create -volname "$name" -srcfolder "$stage" -ov -format UDZO \
        "$out/$file-macos-$arch.dmg"
}

linux_deb() {
    case $(uname -m) in
    x86_64) deb_arch=amd64 ;;
    *) deb_arch=arm64 ;;
    esac
    root="$out/deb"
    rm -rf "${root:?}"
    mkdir -p "$root/DEBIAN" "$root/usr/bin" "$root/usr/share/applications" \
        "$root/usr/share/icons/hicolor/256x256/apps"
    cp "$1/$slug" "$root/usr/bin/$slug"
    cp "$here/packaging/$slug.desktop" "$root/usr/share/applications/"
    cp "$here/assets/icon-256.png" "$root/usr/share/icons/hicolor/256x256/apps/$slug.png"
    cat >"$root/DEBIAN/control" <<CONTROL
Package: $slug
Version: $version
Architecture: $deb_arch
Maintainer: Seyyed Ali Mohammadiyeh <MaxBaseCode@gmail.com>
Depends: libc6, libx11-6, fonts-dejavu-core
Section: utils
Priority: optional
Homepage: https://github.com/BaseMax/salam-calculator
Description: A precise, friendly calculator written in Salam
CONTROL
    dpkg-deb --root-owner-group --build "$root" "$out/$file-linux-$(uname -m).deb"
}

build_linux() {
    stage="$out/linux/$slug"
    rm -rf "${out:?}/linux"
    mkdir -p "$stage"
    "$salam" build "$here" --ui=native --backend=native --linker=system -o "$stage/$slug"
    cp "$here/packaging/$slug.desktop" "$here/LICENSE" "$stage/"
    cp "$here/assets/icon-256.png" "$stage/$slug.png"
    tar -C "$out/linux" -czf "$out/$file-linux-$(uname -m).tar.gz" "$slug"
    if command -v dpkg-deb >/dev/null 2>&1; then
        linux_deb "$stage"
    fi
}

build_windows() {
    stage="$out/windows/$name"
    rm -rf "${out:?}/windows"
    mkdir -p "$stage"
    "$salam" build "$here" --ui=native --target=x86_64-w64-windows-gnu --backend=native \
        --subsystem=windows --icon="$here/assets/icon.ico" \
        "--version-info=version=$version" "--version-info=product=$name" \
        "--version-info=description=$name" -o "$stage/$slug.exe"
    cp "$here/LICENSE" "$stage/LICENSE.txt"
    (cd "$out/windows" && zip -qr "../$file-windows-x86_64.zip" "$name")
}

build_android() {
    stage="$out/android"
    set -- app android "$here/main.salam" --out "$stage" --abi all \
        --version "$version" --build "$(build_number)"
    kind=debug
    if [ -n "${ANDROID_KEYSTORE:-}" ]; then
        set -- "$@" --release --keystore "$ANDROID_KEYSTORE" \
            --key-alias "${ANDROID_KEY_ALIAS:?}"
        kind=release
    fi
    "$salam" "$@"
    cp "$stage/app.apk" "$out/$file-android-$kind.apk"
}

build_ios() {
    "$salam" app ios "$here/main.salam" --out "$out/ios-simulator" \
        --version "$version" --build "$(build_number)"
    (cd "$out/ios-simulator" && zip -qry "../$file-ios-simulator.zip" App.app)
    "$salam" app ios "$here/main.salam" --out "$out/ios-device" --ipa \
        --version "$version" --build "$(build_number)"
    cp "$out/ios-device/App.ipa" "$out/$file-ios-unsigned.ipa"
}

mkdir -p "$out"
out=$(cd "$out" && pwd)
case $platform in
macos | linux | windows | android | ios) "build_$platform" ;;
*)
    echo "usage: build.sh [macos|linux|windows|android|ios]" >&2
    exit 2
    ;;
esac
echo "Built $platform $version in $out"
