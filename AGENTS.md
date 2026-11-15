# Agent Guide

## Project

Cactus Pocket is a Flutter/Dart Android app with Kotlin and C++ JNI integration for local Cactus Mirage inference. The target device is ARM64 Android. Android build tooling is managed by `devenv`.

## Development environment

Enter the project environment with:

```sh
devenv shell
```

Use these checks before committing app changes:

```sh
devenv shell -- test-solution
devenv shell -- prek run --all-files
```

`test-solution` runs Flutter analysis and tests, builds the debug APK, checks for `lib/arm64-v8a/libcactus_jni.so`, then installs and launches the app on the first authorized ADB device. It does **not** test the app's interactive model-download/gallery/inference flows or airplane-mode behavior; verify those manually and record evidence. A connected device is required for the install/launch portion.

## Code quality

- Dart formatting and linting: `dart format` and `flutter analyze` (`cactus_pocket/analysis_options.yaml`).
- Kotlin formatting/lint: `ktlint`; analysis: `detekt`.
- Pre-commit hooks are configured in `.pre-commit-config.yaml` and run through `prek` in devenv.
- Current Nixpkgs provides prek 0.5.5. Keep `minimum_prek_version` compatible with the version in devenv unless the package is explicitly upgraded.

## OpenSpec

Active change: `openspec/changes/mirage-android-offline-app`.

Before implementation, read its `RESUME.md`, task list, and use the `openspec-apply-change` skill. Do not mark physical-device integration or offline behavior complete without direct evidence. Preserve existing commits; do not reset or amend them.

## Device acceptance still needed

On the connected Xiaomi 23049PCD8G (Android 15/API 35/ARM64): download the pinned model in-app while online, verify checksum/readiness persists after relaunch, select a gallery image, run inference, test recoverable failure states, then repeat inference in airplane mode. Update OpenSpec tasks and README with actual results only.
