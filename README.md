# Cactus Pocket

Flutter Android app for local Cactus Mirage image descriptions. The model is stored in app-private storage; image inference runs on-device without an inference-time network service.

## Requirements

- Nix with flakes enabled and `devenv`
- ARM64 Android phone with USB debugging authorized
- Android API 24 or later (current tested device: Xiaomi 23049PCD8G, Android 15/API 35)
- Internet for the initial model download; allow at least 22 MB for the pinned model plus temporary download space

The devenv environment provides Flutter 3.47.4, Java 17, Android SDK Platforms 34, 35, and 36, Build Tools 36.0.0, platform-tools, and NDK 28.2.13676358. The app compiles against API 36 and targets API 35; the target SDK remains unchanged. Android Gradle Plugin 9.0.1, Kotlin Gradle Plugin 2.3.20, and Gradle wrapper 9.3.1 are pinned in the Android project. Flutter's Android dependency validation stays enabled. Emulator images are not required. Gradle uses `FLUTTER_ROOT` for the Flutter plugin and the Android SDK/NDK paths supplied by devenv. Do not add machine-specific SDK paths to `android/local.properties`.

## Build and install

```sh
devenv shell
cd cactus_pocket
flutter doctor -v
flutter doctor --android-licenses
adb devices -l
flutter analyze
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.cactuscompute.cactus_pocket 1
```

`devenv shell -- test-solution` runs analysis, tests, debug APK build, ARM64 JNI packaging checks, and install/launch on the first authorized ADB device. Confirm its build output has no Flutter warnings that the AGP or Kotlin plugin version will soon be unsupported. A connected phone is needed for the install/launch steps. No generated local SDK properties file is required.

## Use

1. Connect to the internet and open Mirage.
2. Tap **Get model**. The app downloads the pinned model, reports progress, verifies SHA-256, then loads it. Only the verified file is promoted to the ready-model path.
3. Tap **Choose image**, select an image from the gallery, then tap **Describe**.
4. Read the description or expand **Raw response JSON**. Camera capture and visual overlays are not included.
5. Once the model is ready, enable airplane mode or otherwise disconnect the network and run inference again. Image decoding and `cactus_describe` are local.

Cancelled, interrupted, incomplete, or checksum-mismatched downloads are not considered ready. A failed setup displays an error and allows retry. If storage is low, free space and retry; the app reports storage write failures and removes temporary partial files.

## Pinned artifacts and licenses

- **Native runtime:** Cactus 4.1.1 Android ARM64 static archive, Hugging Face revision `d2c5cd70432ed78345f3ba6b620bff2feeec6c86`, [artifact](https://huggingface.co/Cactus-Compute/cactus/resolve/d2c5cd70432ed78345f3ba6b620bff2feeec6c86/releases/4.1.1/android-arm64/libcactus.a), 2,822,132 bytes, SHA-256 `01b91dae81d7e94ce55691376838d8b10453d33d7433ddd1b59bf4a9669012b9`, Apache-2.0. It is linked into the app's ARM64 `libcactus_jni.so`.
- **Mirage model:** `Cactus-Compute/mirage`, revision `76c1e9e53381aca8fc3843c636216c96ff220122`, [model](https://huggingface.co/Cactus-Compute/mirage/resolve/76c1e9e53381aca8fc3843c636216c96ff220122/mirage.cact), 21,611,043 bytes, SHA-256 `4249a0f7515272ff76b9414bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237`; model card declares Apache-2.0.
- **Inference contract:** the app uses Cactus `cactus_load`, `cactus_models`, `cactus_last_error`, and `cactus_describe`; it does not use a CLI image option or a cloud inference API.

The official Cactus Flutter plugin is not reused; its license is restricted and its FFI does not expose the dedicated `cactus_describe` API. Review upstream licenses before redistributing or modifying third-party artifacts.

## Verification and device notes

The tested phone is Xiaomi 23049PCD8G (`marble`), Android 15/API 35, `arm64-v8a`. The documented deterministic gallery fixture is the Cactus Compute logo at `https://cactuscompute.com/assets/cactus_white.png` (original SHA-256 `ceb154d0478940e6a8cf20de22a597b34a2e921211ddc8d701e5073828c1c56c`, 896x880 RGBA).

The model was downloaded in-app, checksum-verified, and loaded after relaunch. A fresh gallery inference after relaunch in airplane mode returned `white · minimalist`. During device acceptance, `cactus_load` took 38 ms and a 512x512 native `cactus_describe` call returned in 273 ms; an app-process memory snapshot after inference showed about 439,726 KB PSS and 164,881 KB native heap. These memory figures are a single snapshot, not peak measurements, and the timings are native harness measurements rather than end-to-end Flutter timings. See [`openspec/changes/mirage-android-offline-app/design.md`](openspec/changes/mirage-android-offline-app/design.md) for full acceptance evidence and limitations.

## Troubleshooting

- **No device listed:** unlock the phone, enable USB debugging, accept the authorization prompt, and rerun `adb devices -l`.
- **Android SDK/NDK not found:** enter `devenv shell`; do not hard-code local SDK paths. Check `FLUTTER_ROOT`, `ANDROID_HOME`, and `ANDROID_NDK_ROOT` in that environment.
- **Model download failed:** reconnect to the internet, check free app storage, then tap **Get model** again. The app retains no eligible partial model after a failed download.
- **Model checksum/load failure:** retry the download. The pinned digest is checked before the model can be loaded.
- **Gallery image rejected:** choose a supported, decodable image (JPEG or PNG); camera capture is out of scope.
- **Native inference error:** confirm the model status is ready and retry with another image. Inference does not fall back to a network service.
