# Cactus Pocket

Flutter Android starter for exploring local Cactus Mirage inference.

## Development environment

Requirements: Nix with flakes enabled, `devenv`, and a physical Android phone with USB debugging enabled. The devenv Android integration provides Flutter and the Android SDK tools. It is configured for Android API 35 and build-tools 35.0.0; emulator binaries/system images, Google APIs, NDK and CMake are disabled to reduce the environment. Re-enable NDK/CMake if the Mirage bridge needs native compilation.

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

The first build can take a while while Gradle fetches dependencies.

The `cactus_pocket/` directory is the Flutter app. The app is only Flutter's generated starter, not Mirage-enabled yet. Mirage inference requires a verified Android runtime bridge and pinned model/runtime versions; see `PLAN.md` before implementing it.

## Current status

- `devenv.nix` uses devenv's Android integration with Flutter support and no emulator.
- A physical Android device is the intended test target; no connected device was detected during setup.
- No Mirage model or native inference runtime has been integrated.
