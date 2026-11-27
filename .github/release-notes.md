Salam Calculator @VERSION@, written entirely in the
[Salam programming language](https://github.com/SalamLang/Salam).

| System | File | How to start |
| --- | --- | --- |
| macOS, Apple silicon | `SalamCalculator-@VERSION@-macos-arm64.dmg` | Drag the app to Applications. It is not notarized: right click it and choose Open the first time. |
| macOS, Intel | `SalamCalculator-@VERSION@-macos-x86_64.dmg` | Same as above. |
| Windows 64-bit | `SalamCalculator-@VERSION@-windows-x86_64.zip` | Unzip and run `salam-calculator.exe`. It is not signed, so SmartScreen may ask: choose More info, then Run anyway. |
| Linux | `SalamCalculator-@VERSION@-linux-x86_64.deb` or `-aarch64.deb` | `sudo apt install ./<file>.deb` |
| Linux, any distribution | `SalamCalculator-@VERSION@-linux-<arch>.tar.gz` | Unpack and run `salam-calculator`. Needs libX11. |
| Android | `SalamCalculator-@VERSION@-android-*.apk` | Open the file on the phone and allow the install. |
| iPhone and iPad | `SalamCalculator-@VERSION@-ios-unsigned.ipa` | Not signed. Sign it with your own Apple ID, for example with AltStore or Sideloadly. |
| iOS Simulator | `SalamCalculator-@VERSION@-ios-simulator.zip` | Unzip, then `xcrun simctl install booted App.app`. |

An APK whose name ends in `-debug` is signed with a temporary key: uninstall it
before installing a newer build.

`SHA256SUMS` lists the checksum of every file.
