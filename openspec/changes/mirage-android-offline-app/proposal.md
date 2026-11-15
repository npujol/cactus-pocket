# Proposal

## Why

Cactus Pocket currently contains only a Flutter starter app. The Android app must be able to run Cactus Mirage on a physical phone, using a locally stored model and native Android runtime, without network access during inference. Before adding the product UI, the Android build setup must also be repeatable and a real `cactus_describe` call must be proven on-device.

## What Changes

- Make the Flutter/Android build reproducible with devenv/direnv for the ARM64 physical-phone target; do not require emulator images or untracked machine-specific SDK paths.
- Pin and verify a compatible Cactus Android runtime and Mirage model, including versions, license/source and model integrity.
- Implement app-private model download/storage and an Android-native bridge from Flutter to the dedicated Mirage `cactus_describe` API.
- Prove inference on the connected phone before completing the image-analysis UI; then add gallery input, result rendering, error/progress states and airplane-mode validation.
- Document setup, model management, offline use, device limits and verification results.

## Capabilities

### New Capabilities
- `android-build`: Reproducible devenv/Flutter Android build and physical-device workflow for the ARM64 phone target.
- `mirage-inference`: Download and retain the pinned Mirage model, invoke local native `cactus_describe` with an image, and expose structured results and errors to Flutter.
- `offline-vision-app`: Select an image, show inference state/results, and run inference without network after model setup.

### Modified Capabilities

## Impact

- Project environment and Android build configuration: `devenv.nix`, Flutter Gradle configuration and generated Android project under `cactus_pocket/`.
- Flutter application in `cactus_pocket/lib/`, dependencies and tests.
- Android native code/JNI or FFI integration and packaged ARM64 runtime artifacts.
- App-private model download/storage and permissions/network behavior.
- OpenSpec capabilities/specifications and project setup/offline-use documentation.
