# Proposal

## Why

The Flutter 3.47.4 debug build warns that the project's pinned Android Gradle Plugin (8.11.1) and Kotlin plugin (2.2.20) will soon fall outside Flutter's supported versions. Aligning the Android toolchain with Flutter's supported versions avoids these specific compatibility warnings while preserving the reproducible ARM64 device build.

## What Changes

- Upgrade the pinned Android Gradle Plugin and Kotlin plugin to versions accepted by the configured Flutter SDK; account for any required Gradle wrapper or Android project configuration changes.
- Keep the Android SDK/NDK, Java, ARM64 JNI packaging, and connected-device build workflow reproducible through devenv.
- Verify the debug build no longer emits the two Flutter AGP/Kotlin support warnings, without suppressing Flutter's dependency validation.
- Update build setup documentation with the resulting toolchain versions and verification command.

This targets the two Flutter support warnings shown in the reported build output; it does not promise to remove unrelated warnings from other tools.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `android-build`: Require Flutter-supported Android Gradle Plugin and Kotlin versions and a debug build free of Flutter's corresponding support warnings.

## Impact

- `cactus_pocket/android/settings.gradle.kts`, Gradle wrapper and any Android Gradle configuration affected by the selected plugin versions.
- `devenv.nix` verification workflow and root `README.md` build documentation.
- Flutter debug APK build and ARM64 JNI packaging/device-install checks; no app runtime behavior or native inference API changes.
