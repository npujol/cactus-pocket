# Tasks

## 1. Stabilize the Android development workflow

- [ ] 1.1 Inspect devenv and Flutter-generated Android configuration; identify SDK/NDK source and exact version requirements.
- [ ] 1.2 Remove reliance on untracked machine-specific `local.properties` paths; configure devenv/Gradle SDK and NDK paths reproducibly without emulator images.
- [ ] 1.3 From a clean shell, run Flutter analysis/tests and build the debug APK.
- [ ] 1.4 Install and launch on the connected ARM64 phone; investigate and document the `flutter run` device disconnect separately from app health.
- [ ] 1.5 Update root setup docs with verified build/install commands and any device-specific prerequisites.

## 2. Verify and pin Mirage artifacts

- [ ] 2.1 Inspect current Cactus Android ARM64 release artifacts, API header/exports, runtime version, and supported model format.
- [ ] 2.2 Verify the runtime exposes `cactus_load`, `cactus_models`, `cactus_last_error`, and `cactus_describe`; confirm the exact function signatures and memory ownership.
- [ ] 2.3 Select and pin compatible runtime/model revisions; record source URLs, licenses, ABI, file sizes and SHA-256 checksum.
- [ ] 2.4 Confirm redistribution and plugin reuse terms; choose JNI/NDK linkage or a licensed plugin extension based on findings.
- [ ] 2.5 Document unresolved compatibility/license blockers before proceeding if artifacts cannot be legally or technically used.

## 3. Prove one on-device native inference call

- [ ] 3.1 Add the minimal Android native bridge and package/link the verified ARM64 runtime.
- [ ] 3.2 Implement model load/status and `cactus_describe` call with explicit buffer ownership and serialized background execution.
- [ ] 3.3 Use a known test image; validate orientation, RGB layout, dimensions and options against the reference API.
- [ ] 3.4 Run the call on the phone and capture the raw response, load/inference time, memory behavior and failure cases.
- [ ] 3.5 Add focused tests for image conversion, native error propagation and bridge state/lifecycle.

## 4. Implement model acquisition and image-analysis UI

- [ ] 4.1 Add app-private persistent storage and a pinned HTTPS model download with progress, cancellation, retry, checksum verification and insufficient-space handling.
- [ ] 4.2 Add gallery image selection and a correctly oriented preview; handle unsupported images and decode failures.
- [ ] 4.3 Replace the starter screen with the compact dark Mirage interface: upload action, preview, description and expandable raw JSON.
- [ ] 4.4 Add explicit model/download/inference states, disable conflicting actions while native calls are active, and provide recoverable errors.
- [ ] 4.5 Add response parsing tests; only implement visual overlays after field schema and coordinate semantics are verified.

## 5. Validate offline behavior and document delivery

- [ ] 5.1 Download and verify the model while online; confirm it persists across app relaunch.
- [ ] 5.2 Enable airplane mode and run inference on a local image; verify no inference-time HTTP/cloud dependency.
- [ ] 5.3 Record phone/Android/runtime/model versions, model size, minimum observed free storage, load time, inference latency, memory behavior and limitations.
- [ ] 5.4 Document setup, build/install, model download, offline use, licenses/sources, device requirements and troubleshooting.
- [ ] 5.5 Run final Flutter analysis/tests and a physical-device build/install; summarize remaining risks.
