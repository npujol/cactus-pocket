# Design

## Context

The repository now contains a generated Flutter Android app and a devenv environment. The starter APK has been built, installed, and launched on a Xiaomi 23049PCD8G (Android 15/API 35, ARM64). Builds have relied on a writable SDK path during troubleshooting; the committed SDK/NDK setup is not yet proven reproducible. A stable `flutter run` connection has not been confirmed. Mirage inference is not implemented.

Research in `PLAN.md` identifies the native `cactus_describe(rgb, width, height, options, language, keywords, out, out_capacity)` API and an Android ARM64 runtime artifact. The official Flutter plugin currently does not expose this dedicated Mirage API. The documented runner does not accept an image flag. Runtime/model revisions, ABI exports, artifact redistribution terms, and model checksum must be verified before implementation.

## Goals / Non-Goals

**Goals:**
- Reproducibly build/install the Flutter app using devenv on an ARM64 physical phone, with no emulator requirement.
- Prove one pinned Mirage model/runtime inference call on the phone before building the full user flow.
- Keep the model in app-private storage and perform inference locally after download.
- Provide a safe Flutter-to-native interface and useful output/error states.

**Non-Goals:**
- Emulator coverage or non-Android platforms.
- NPU acceleration unless a compatible documented Android path is confirmed.
- Cloud inference or inference-time network access.
- Camera capture, segmentation/box overlays, or rich result visualization before the core native call and response schema are validated.
- Copying plugin code or redistributing artifacts without confirming license terms.

## Decisions

1. **Physical phone as the acceptance target.** Use the connected ARM64 Xiaomi phone and ADB; do not install emulator images. This matches the requested deployment and avoids making emulators a prerequisite.
2. **Stabilize the toolchain first.** Resolve SDK/NDK paths and pin build tools in devenv/Gradle. Treat fresh-shell debug APK build and device install as a gate before runtime integration.
3. **Vertical-slice inference before UI expansion.** Pin a runtime release and model revision; verify Android exports and licensing; run `cactus_describe` on a known image on the phone and record response, latency, and memory behavior before designing around unverified output.
4. **Use the dedicated native API.** Implement a small Android JNI/native bridge (or extend the Flutter plugin only if its license and ABI are suitable) and call `cactus_describe`; do not route image inference through the CLI runner or generic vision completion API.
5. **App-private persistent model storage.** Download the pinned `.cact` model over HTTPS, verify its pinned checksum before loading, and persist it in app-private storage. Network is only for initial model acquisition; inference must not fall back to a service.
6. **Keep native operations off the UI thread and serialized.** Define ownership/lifetime for model state and native buffers, reject overlapping model operations, and return explicit errors across the platform channel. Use a worker thread/dispatcher for blocking inference.
7. **Start with gallery input and inspectable output.** Handle EXIF orientation, RGB packing, and image dimensions explicitly; expose the returned text and raw response. Add overlays only after schema and coordinate semantics are established.

## Risks / Trade-offs

- Published artifacts may not export `cactus_describe`, may be incompatible with the pinned model, or may have unclear redistribution terms; verify before committing to integration.
- NDK path/version mismatch is already a known source of build issues and may require a local writable SDK arrangement; avoid silently encoding machine-specific paths.
- Device memory, thermal behavior, and latency are unknown; a successful model load does not guarantee usable interactive inference.
- Image decode/color/orientation mistakes can silently corrupt model input; cover conversion with tests and known-image checks.
- Model checksums and versions can change upstream; pin them explicitly and make upgrades deliberate.
- Flutter debug transport may drop after launch on this device; distinguish app/runtime health from ADB/debug-session health and record reproducible workarounds.
- Airplane-mode validation must be performed after model download and must check actual inference, not only app startup.
