# Cactus Pocket — Project Plan

## Goal

Build a Flutter Android app in `/home/nainai/projects/cactus-pocket` that runs **Cactus Mirage locally on the phone**, with no network required after setup. The app should let the user choose/take a photo, run Mirage, and show the result in an interface inspired by the supplied screenshot (`/tmp/pi-clipboard-91d3dba1-8278-40ae-a4a1-717df5c2aa71.png`). Target Mirage output includes scene description and structured results for objects, text/OCR, segmentation masks, spatial relations and forms where supported by the API.

## Research completed

- Mirage announcement, architecture, example outputs and model description: https://cactuscompute.com/blog/mirage
- Mirage model repository and downloadable weights: https://huggingface.co/Cactus-Compute/mirage
  - `mirage.cact` is about 21.6 MB (roughly 22 MB); `mirage.safetensors` is a much larger training/reference artifact and is not the mobile runtime weights needed here.
- Cactus runtime repository and supported platform artifacts: https://huggingface.co/Cactus-Compute/cactus
  - Android ARM64 artifacts are published under `releases/<version>/android-arm64/`; these include a runner, `libcactus.a`, and `cactus.h`.
  - The native header exposes `cactus_load(...)`, `cactus_models()`, `cactus_last_error()` and `cactus_describe(rgb, width, height, options, language, keywords, out, out_capacity)`.
  - The runner CLI documented in the repository has text/audio flags, not an image flag. Do not use `--image` with that runner.
- Runtime source/API and reference Mirage implementation: https://github.com/cactus-compute/cactus
  - Python Mirage API reference: https://github.com/cactus-compute/cactus/blob/main/cactus/agent/mirage.py
  - Python Mirage CLI implementation: https://github.com/cactus-compute/cactus/blob/main/cactus/cli/vision.py
  - The Python API decodes images to RGB and calls `cactus_describe`; it is useful as a behavioral reference, but its Python package/runtime wheels are not the Termux Android solution.
- Official Flutter plugin: https://github.com/cactus-compute/cactus-flutter
  - Contains Android native libraries and a Flutter example image-analysis screen (`example/lib/pages/vision.dart`).
  - Its example handles model selection/download, image picking, initialization and UI, but uses a general vision-capable LLM completion path—not Mirage's dedicated `cactus_describe` API or structured Mirage results. The plugin's current FFI bindings do not expose `cactus_describe`; this project needs a Mirage-specific Android/native bridge or a suitable extension to the plugin.
  - License metadata reported by GitHub as `NOASSERTION`; inspect its LICENSE before copying/adapting code. Prefer treating it as a reference unless license terms are verified.
- Image UI reference supplied by the user: `/tmp/pi-clipboard-91d3dba1-8278-40ae-a4a1-717df5c2aa71.png`.

## Current status

- [x] Created a Flutter Android starter app in `cactus_pocket/`.
- [x] Added a devenv/direnv environment with a phone-focused Android setup (no emulators).
- [x] Built, installed and launched the starter app on a Xiaomi 23049PCD8G (Android 15, API 35).
- [x] Committed the work in small commits; the root repository working tree is clean.
- [ ] Verify a fresh Android build without ignored `local.properties`. Gradle now uses `FLUTTER_ROOT`; the devenv config enables the pinned NDK, but the clean-config APK build has not yet been re-run.
- [ ] Keep a stable Flutter debug connection to the phone; `flutter run` has reported device connection loss even though the installed app launched.
- [ ] No Mirage model, runtime bridge, image input, or inference UI is implemented.
- Cactus 4.1.1 publishes an Android ARM64 header/archive manifest with `cactus_describe`; model revision `3d03cee88c0acbe4e71b94b567ab14e6e55f40c9` has SHA-256 `4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237`. Actual runtime/model compatibility remains unproven on-device.
- The official Flutter plugin license is restricted to qualifying non-commercial users; do not reuse it unless eligibility is established or a commercial license is obtained.

## Implementation plan

The active implementation proposal, requirements, design, and task checklist are maintained as an OpenSpec change: [`openspec/changes/mirage-android-offline-app/`](openspec/changes/mirage-android-offline-app/). Use those artifacts as the source of truth for implementation; this file retains research notes and current project status.

1. **Stabilize the development baseline**
   - Inspect the committed devenv and Flutter Android configuration; remove reliance on untracked machine-specific paths such as `android/local.properties`.
   - Resolve SDK/NDK setup so a fresh shell can build the APK reproducibly without emulator images.
   - Run Flutter analysis/tests, build and install on the connected ARM64 phone, and check whether the debug connection stays alive. Record any device-specific workaround.
   - Keep this separate from Mirage integration: the starter app must build and launch reliably first.

2. **Confirm technical baseline and licenses**
   - Inspect `cactus-pocket` contents and choose Flutter project structure.
   - Check `cactus-flutter` license and current Android ABI/version compatibility.
   - Confirm exact Cactus Android runtime version/API and Mirage model revision are compatible; pin versions rather than using floating `main` artifacts.
   - Check Flutter, Android SDK/NDK and the connected physical phone for build/testing. No emulator is required for this project.

3. **Scaffold and build the Flutter application**
   - The generated Flutter starter exists in `cactus_pocket/` and has been installed and launched on the target phone.
   - Replace the starter screen with the screenshot's dark, compact sandbox layout: camera/upload actions, image preview, description panel and expandable JSON output.
   - Add loading, download progress, inference status, errors and offline/model-ready states.

4. **Implement local model management**
   - Download Mirage `.cact` once over HTTPS, save it in app-private storage, and preserve it across launches.
   - Pin and document the model revision, source, license and checksum; verify the checksum before loading.
   - Offer progress, retry, cancellation and clear storage/error handling, including insufficient-space failures.
   - Make model availability explicit. App must not silently attempt network requests during inference.
   - Record model size and establish practical storage and memory requirements on the target phone.

5. **Prove and implement native Mirage inference bridge**
   - First milestone: with pinned runtime/model revisions, load one `.cact` archive and run `cactus_describe` on one known image on the phone. Capture the raw response, load/inference time, memory behavior and errors. Defer full UI work until this succeeds.
   - Integrate the Android Cactus runtime for the selected ABI (initial target: `arm64-v8a`).
   - Ensure the linked native library exports the current Mirage APIs (`cactus_load`, `cactus_models`, `cactus_describe`, `cactus_last_error`). Verify the official Flutter plugin's bundled `.so` version/API before reusing it; its checked-in FFI currently does not bind the Mirage describe API.
   - Provide a Dart-facing method to load the `.cact` archive and run image inference.
   - Decode chosen/captured image, apply orientation, resize if appropriate, convert to packed RGB bytes, pass dimensions/options and parse returned JSON.
   - Run native work off the UI thread where feasible; manage native buffers, memory, lifecycle, cancellation and model unload safely. Provide actionable load/inference errors and recovery without restarting the app where feasible.

6. **Add image input and result UI**
   - Support gallery picker first; add camera capture and permissions.
   - Render image preview, description and JSON; add overlays for boxes/masks only after confirming exact JSON schema and coordinates from the model/API.
   - Keep output inspectable and provide useful failure messages.

7. **Validate offline operation**
   - Build/install on the target ARM64 Android phone.
   - Download model while connected, run a sample image, then enable Airplane mode and repeat.
   - Verify there are no inference-time HTTP/cloud dependencies; inspect app permissions/network behavior.
   - Record device, Android version, model load time, inference latency, memory behavior and known limitations. Do not assume the blog's Galaxy S26 NPU timing applies to other devices; start with the supported CPU path unless verified acceleration exists.

8. **Document delivery**
   - Add setup, build, run and offline-use instructions, minimum device/storage requirements, model source/version/license and troubleshooting.
   - Include tests for model state, image conversion, native error handling and response parsing where feasible.

## Constraints and caveats

- Current tested device: Xiaomi 23049PCD8G, Android 15/API 35, ARM64. Starter APK built, installed and launched. A stable Flutter debug session is not yet confirmed.
- Emulator coverage is not required; prioritize the physical phone workflow.

- The Termux `pip install cactus-compute` route is not supported for Android/Bionic; the observed Python/Expat failure is separate from Mirage inference.
- The Android command-line runner does not provide image inference through `--image`; use the native Mirage API.
- The standalone Android runtime artifacts and model must be present locally before airplane-mode testing.
- The Flutter starter and development environment are committed. The SDK/NDK setup has not yet been proven reproducible from a fresh checkout; stabilize it before Mirage integration.
- NPU support/performance is device-specific and outside the initial CPU-based MVP unless Cactus provides a compatible documented Android acceleration path.
