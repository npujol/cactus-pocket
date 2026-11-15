# Design

## Context

The repository contains a generated Flutter Android starter and a devenv environment. The starter has previously been built, installed, and launched on a Xiaomi 23049PCD8G (Android 15/API 35, ARM64), but the committed SDK/NDK setup is not proven reproducible. `cactus_pocket/android/local.properties` exists locally but is ignored and contains machine-specific `/nix/store` paths. `devenv.nix` pins Android platform/build-tools and an NDK version, while `ndk.enable` is false; actual Gradle SDK/NDK discovery and availability must be verified. Mirage inference is not implemented.

Research identifies Cactus runtime 4.1.1 (`releases/4.1.1/android-arm64`, HF revision `d2c5cd70432ed78345f3ba6b620bff2feeec6c86`) and Mirage model revision `76c1e9e53381aca8fc3843c636216c96ff220122`. Their pinned hashes and Apache-2.0 licenses are recorded in tasks.md. The matching header declares `cactus_load`, `cactus_models`, `cactus_last_error`, and `cactus_describe`; the static archive exports all four. Cactus source pins this exact runtime/model pair for Mirage. The official Flutter plugin has a custom license limited to qualifying personal/non-commercial use, and does not expose the dedicated describe API; it is not reused.

A temporary NDK 28.2 harness confirms the runtime/model pair on the target phone: `cactus_load=0`, `cactus_models()=4` in 38 ms; `cactus_describe` returned 110 in 273 ms for a 512x512 packed RGB fixture, without network calls. Raw response: `{"scene":{"background":"white","style":"minimalist"},"objects":[{"id":1,"name":"logo","bbox":[4,7,996,993],"score":0.397,"mask":[12,8,8,12,8,988,12,992,27,992,988,992,992,988,992,980,992,12,988,8,980,8],"position":"center","description":{"color":"white and gray","shape":"hexagonal"}}],"regions":[],"text":[],"relations":[],"events":[],"reasoning":"lang: en | white and gray hexagonal logo centered on white | logos are brand marks, hexagonal shape is a geometric emblem | minimalist style uses few colors and simple shapes | cannot know the brand name or what it represents"}`.

## Goals / Non-Goals

**Goals:**
- Reproducibly build/install the Flutter app using devenv on an ARM64 physical phone, with no emulator requirement or untracked SDK paths.
- Resolve and document artifact, API, compatibility and license facts before choosing native integration.
- Prove one verified Mirage model/runtime inference call on the phone before building the full user flow.
- Keep the model in app-private storage and perform inference locally after acquisition.
- Provide a safe Flutter-to-native interface and useful output/error states.

**Non-Goals:**
- Emulator coverage or non-Android platforms.
- NPU acceleration unless a compatible documented Android path is confirmed.
- Cloud inference or inference-time network access.
- Camera capture, segmentation/box overlays, or rich result visualization before the core native call and response schema are validated.
- Copying plugin code or redistributing artifacts without confirming license terms.

## Decisions

1. **Physical phone as acceptance target.** Use the connected ARM64 Xiaomi phone and ADB; do not install emulator images. Record that debug transport failures are distinct from app health.
2. **Make Gradle path discovery explicit.** Inspect devenv and generated Gradle configuration; document the actual SDK/NDK source. Remove any requirement for locally edited ignored `local.properties`. Verify the configured NDK is installed and accessible; reconcile `ndk.enable = false` with the version pin rather than assuming it works.
3. **Artifact and license verification is a gate.** Identify one immutable Android ARM64 runtime artifact and model revision, obtain their source/version/size/license details, verify model SHA-256 and compatibility, and inspect the runtime header/exports. If licensing or technical compatibility is uncertain, document the blocker and do not proceed to native packaging.
4. **Freeze the native contract before bridge implementation.** Record exact signatures, return/error semantics, buffer capacity and ownership, model-load/unload lifetime, and threading constraints for every used API. Choose JNI or another bridge only after this is known.
5. **Vertical-slice inference before UI expansion.** Use a stable, checked-in or otherwise reproducibly identified test image. Confirm orientation, RGB channel order/packing, dimensions and options against the verified API; run on the phone and record raw response, latency and memory behavior before designing around response fields.
6. **App-private persistent model storage.** Download from the pinned HTTPS source into a temporary path, hash before promotion to the ready path, and never load a partial or mismatched file. Cancellation/interruption must preserve this invariant. Network is only for initial model acquisition; inference must not fall back to a service.
7. **Serialize native work off the UI thread.** Define a single model-operation lifecycle, reject unsafe concurrent operations, follow verified buffer ownership, and translate native failures to structured platform errors.
8. **Gallery-first UI.** Handle EXIF orientation, RGB conversion and decode errors. Display returned description and raw response. Defer camera and overlays until after MVP and schema/coordinate verification.

## Risks / Trade-offs

- On-device runtime/model compatibility is demonstrated by the temporary smoke test. Remaining integration risks include ABI packaging/link flags, memory/latency under app lifecycle, and image conversion correctness on gallery photos.
- NDK path/version mismatch is a known build risk; the NDK must actually be present and Gradle-accessible without hard-coded machine paths.
- Device memory, thermal behavior and latency are unknown; model loading does not guarantee usable interactive inference.
- Image decode/color/orientation mistakes can silently corrupt input; test conversion using deterministic fixtures and phone inference.
- Model checksums and versions can change upstream; pin them explicitly and make upgrades deliberate.
- Flutter debug transport may drop after launch on the device; report app health separately.
- Airplane-mode validation must test an actual inference after relaunch, not just app startup or cached output.
