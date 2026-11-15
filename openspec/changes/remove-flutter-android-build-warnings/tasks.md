# Tasks

## 1. Upgrade the Flutter Android toolchain

- [x] 1.1 Check Flutter 3.47.4, AGP, Kotlin Gradle Plugin, Gradle wrapper, and Java compatibility; pin AGP 9.0.1 and Kotlin 2.3.20, declare Build Tools 36.0.0 and SDK Platform 36 in devenv, set app compileSdk to 36 while keeping targetSdk 35, and upgrade `image_picker_android` to 0.8.13+1; verify `flutter build apk --debug` succeeds without either Flutter plugin support warning.
- [x] 1.2 Update the README's documented Android toolchain versions (including Build Tools 36.0.0 and Gradle plugin versions) and build verification command; verify documentation matches Gradle settings, wrapper, devenv, and the `image_picker_android` pin.

## 2. Verify integration and device workflow

- [x] 2.1 Run `devenv shell -- test-solution`; verify Flutter analysis/tests and APK build pass, `lib/arm64-v8a/libcactus_jni.so` is packaged, neither targeted support warning appears, and the app installs and launches on an authorized ARM64 device.
- [x] 2.2 On Xiaomi 23049PCD8G (Android 15/API 35), the upgraded Photo Picker opened, a gallery item was selected, and the app returned with its image preview and enabled Describe button.
