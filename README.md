# Cactus Pocket

Flutter Android starter for exploring local Cactus Mirage inference.

## Development environment

Requirements: Nix with flakes enabled, `devenv`, and an ARM64 Android phone with USB debugging enabled. The devenv Android integration provides Flutter, Java 17, Android API 35, build-tools 35.0.0, platform-tools, and NDK 28.2.13676358. Emulator system images and Google APIs are not required. Gradle gets the Flutter SDK from `FLUTTER_ROOT` and Android SDK/NDK from the devenv environment; `android/local.properties` is optional for Flutter's generated metadata and must not be used for machine-specific SDK paths.

```sh
devenv shell
cd cactus_pocket
flutter doctor -v
flutter doctor --android-licenses
adb devices
```

Authorize the phone's USB debugging prompt. Check that it appears, then run:

```sh
adb devices
flutter run
```

From a fresh checkout, run the following in the devenv shell. No local SDK properties file is needed:

```sh
cd cactus_pocket
flutter analyze
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.cactuscompute.cactus_pocket 1
```

The first build can take a while while Gradle fetches dependencies. On first use, authorize USB debugging on the phone. Check `adb devices` before building/installing. This is a physical-device workflow; no emulator is required.

The `cactus_pocket/` directory contains the Flutter app. Mirage inference remains gated on a verified, licensed native runtime/model combination; see `PLAN.md` and the active OpenSpec change.

The verified build baseline uses devenv's immutable Android SDK including NDK 28.2.13676358. Gradle pins that version, while `FLUTTER_ROOT` resolves the Flutter Gradle plugin. The SDK package includes the NDK, so Gradle does not need to install it with `sdkmanager`.

## Current status

- `devenv.nix` uses devenv's Android integration with Flutter support and no emulator.
- A physical Android device is the intended test target; no connected device was detected during setup.
- No Mirage model or native inference runtime has been integrated.
