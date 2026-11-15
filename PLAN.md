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

## Implementation steps

1. **Confirm technical baseline and licenses**
   - Inspect `cactus-pocket` contents and choose Flutter project structure.
   - Check `cactus-flutter` license and current Android ABI/version compatibility.
   - Confirm exact Cactus Android runtime version/API and Mirage model revision are compatible; pin versions rather than using floating `main` artifacts.
   - Check available Flutter, Android SDK/NDK and device/emulator for build/testing. Flutter was not found in PATH during initial inspection; `adb` was available.

2. **Scaffold Flutter application**
   - Create the Flutter app in this directory.
   - Recreate the screenshot's dark, compact sandbox layout: camera/upload actions, image preview, description panel and expandable JSON output.
   - Add loading, download progress, inference status, errors and offline/model-ready states.

3. **Implement local model management**
   - Download Mirage `.cact` once over HTTPS, save it in app-private storage, and preserve it across launches.
   - Offer progress, retry, integrity verification where a pinned checksum is available, and clear storage/error handling.
   - Make model availability explicit. App must not silently attempt network requests during inference.

4. **Implement native Mirage inference bridge**
   - Integrate the Android Cactus runtime for the selected ABI (initial target: `arm64-v8a`).
   - Ensure the linked native library exports the current Mirage APIs (`cactus_load`, `cactus_models`, `cactus_describe`, `cactus_last_error`). Verify the official Flutter plugin's bundled `.so` version/API before reusing it; its checked-in FFI currently does not bind the Mirage describe API.
   - Provide a Dart-facing method to load the `.cact` archive and run image inference.
   - Decode chosen/captured image, apply orientation, resize if appropriate, convert to packed RGB bytes, pass dimensions/options and parse returned JSON.
   - Run native work off the UI thread where feasible; manage native buffers, memory, lifecycle and model unload safely.

5. **Add image input and result UI**
   - Support gallery picker first; add camera capture and permissions.
   - Render image preview, description and JSON; add overlays for boxes/masks only after confirming exact JSON schema and coordinates from the model/API.
   - Keep output inspectable and provide useful failure messages.

6. **Validate offline operation**
   - Build/install on an ARM64 Android device or emulator.
   - Download model while connected, run a sample image, then enable Airplane mode and repeat.
   - Verify there are no inference-time HTTP/cloud dependencies; inspect app permissions/network behavior.
   - Record device, Android version, model load time, inference latency, memory behavior and known limitations. Do not assume the blog's Galaxy S26 NPU timing applies to other devices; start with the supported CPU path unless verified acceleration exists.

7. **Document delivery**
   - Add setup, build, run and offline-use instructions, minimum device/storage requirements, model source/version/license and troubleshooting.
   - Include tests for model state, image conversion, native error handling and response parsing where feasible.

## Constraints and caveats

- The Termux `pip install cactus-compute` route is not supported for Android/Bionic; the observed Python/Expat failure is separate from Mirage inference.
- The Android command-line runner does not provide image inference through `--image`; use the native Mirage API.
- The standalone Android runtime artifacts and model must be present locally before airplane-mode testing.
- The initial folder was empty and not a Git repository. No app implementation or code changes have been made yet.
- NPU support/performance is device-specific and outside the initial CPU-based MVP unless Cactus provides a compatible documented Android acceleration path.
