# Design

## Context

The repository now contains the Flutter Android Mirage app and a devenv environment. The app has been built, installed, and exercised on a Xiaomi 23049PCD8G (Android 15/API 35, ARM64). Gradle resolves Flutter from `FLUTTER_ROOT` and Android SDK/NDK from devenv; build and install succeeded without relying on machine-specific SDK paths in `local.properties`. The app includes private model storage, the JNI bridge, gallery input, local inference, and result/error UI.

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

- Runtime/model compatibility and the integrated app flow are demonstrated on the target phone, including an actual gallery inference after relaunch in airplane mode. Memory/latency observations are limited to the measurements below; no peak-memory or thermal-soak profile was taken.
- NDK path/version mismatch is a known build risk; the NDK must actually be present and Gradle-accessible without hard-coded machine paths.
- Inference latency varies with device load and image dimensions. The recorded native timing comes from a 512x512 harness call; the Flutter end-to-end path was verified for correctness but not separately instrumented. The memory values below are snapshots, not peak measurements.
- Image decode/color/orientation mistakes can silently corrupt input; test conversion using deterministic fixtures and phone inference.
- Model checksums and versions can change upstream; pin them explicitly and make upgrades deliberate.
- Flutter debug transport may drop after launch on the device; report app health separately.
- The app asks for no inference-time network service; model acquisition is the only app network flow. A failed offline model download was recovered after Wi-Fi returned.

## Device Acceptance Results

Validated on Xiaomi 23049PCD8G (`marble`), Android 15 / API 35, `arm64-v8a`; build environment used Java 17, Gradle 9.3.1, Android build-tools 35.0.0, and NDK 28.2.13676358. No emulator was used.

- Model: Mirage revision `76c1e9e53381aca8fc3843c636216c96ff220122`, 21,611,043 bytes, SHA-256 `4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237`.
- Downloaded in-app while Wi-Fi was validated; the promoted file matched the pinned digest. A subsequent force-stop/relaunch showed the model ready and loaded from app-private storage.
- Failure recovery: with airplane mode on and the model file temporarily absent, download failed with a host-lookup error, displayed a retry action, and left no `.part` or ready model. Wi-Fi restoration and retry downloaded and verified the model.
- Gallery fixture: Cactus Compute logo `https://cactuscompute.com/assets/cactus_white.png`, original SHA-256 `ceb154d0478940e6a8cf20de22a597b34a2e921211ddc8d701e5073828c1c56c`. The original 896x880 image was selected in-app; a fresh result displayed `white · minimalist` and raw JSON.
- Offline acceptance: after relaunch with airplane mode enabled and no available network, the same gallery image produced a fresh `white · minimalist` description. Airplane mode was confirmed active; the on-device model digest remained unchanged.
- Native harness timing on this phone: model load 38 ms; 512x512 `cactus_describe` call returned code 110 in 273 ms. These are native-call measurements, not end-to-end Flutter timings.
- Storage: Android reported 9.2 GB available on `/data` around model acquisition; model size was 21.6 MB. This is the observed free-space value, not a derived minimum requirement.
- `dumpsys meminfo` after app inference showed about 439,726 KB total PSS and 164,881 KB native heap. These are one post-inference snapshot; peak memory, sustained thermal behavior, and low-storage behavior were not profiled.
