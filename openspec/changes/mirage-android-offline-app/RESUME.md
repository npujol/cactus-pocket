# Resume point

## Current state

Active change: `mirage-android-offline-app` (spec-driven). OpenSpec task progress last checked: **14/25 complete**. Repo has uncommitted implementation changes; preserve them. No commit was made.

### Implemented so far
- Android build baseline: `devenv.nix` now includes API 34 + 35, CMake 3.22.1 and pinned NDK 28.2.13676358. Gradle plugin settings use `FLUTTER_ROOT` instead of requiring machine-specific `local.properties`.
- `cactus_pocket/android/app/src/main/cpp/` and `jni/`: direct JNI bridge to Cactus 4.1.1 static library. `ndk-build` generates `jniLibs/arm64-v8a/libcactus_jni.so` via Gradle task; ABI restricted to ARM64. This replaced Gradle CMake because Nix CMake's bundled `ninja --version` segfaults here.
- `CactusNative.kt`, `MainActivity.kt`, `lib/services/cactus_inference.dart`: model load/status + describe bridge, serial executor, RGB/dimensions validation, exception mapping.
- `lib/services/model_store.dart`: pinned HTTPS download, temp file, SHA-256, atomic rename, retry/cancel/progress hooks. Important: recent tests hang; debug this before relying on downloader.
- `lib/services/image_rgb.dart`: EXIF orientation, white alpha composite, packed RGB.
- `lib/main.dart`: dark Mirage UI, model setup/download states, gallery picker, preview, description/raw JSON, errors.
- `image_picker`/related dependencies pinned back to Android API 34-compatible versions; `path_provider_android` pin is being investigated. Current devenv has platforms 34 and 35.
- Dart bridge/image tests added, widget test updated.

### Verified evidence
- Flutter analyze passed immediately before the model-store tests.
- Flutter widget test and inference bridge tests passed; `model_store_test.dart` then timed out (all 3 cases, ~30s each). No reason yet isolated.
- Earlier, before full Flutter integration, an NDK-built temporary harness on Xiaomi 23049PCD8G / Android 15 / API 35 / ARM64 loaded Mirage (Cactus `cactus_load=0`, `cactus_models()=4`, 38 ms) and ran `cactus_describe` on 512x512 RGB in 273 ms, returning structured JSON. Fixture was public Cactus logo (`https://cactuscompute.com/assets/cactus_white.png`, original SHA-256 `ceb154d0478940e6a8cf20de22a597b34a2e921211ddc8d701e5073828c1c56c`).
- The app built and installed/launched before latest dependency/test changes. Latest build after dependency changes not yet passed; prior blocker was SDK-36 requirement from newer dependencies and then `jni` package's CMake/ninja segfault. `jni` should be gone after pinning path_provider_android 2.2.10, but latest state needs `flutter pub deps`/build verification.
- Model expected SHA-256 is `4249a0f7515272ff76b941bec17d7e7daf84b15b66c7fb4f17fce1e66f9f237` (64 chars). Verify actual literal in `lib/services/model_store.dart`; it was corrected after accidental editing.

## Next steps
1. Read current `openspec instructions apply --change mirage-android-offline-app --json`; progress may need refresh.
2. Inspect `pubspec.yaml`/lock to ensure `jni`, `jni_flutter`, `jni_util` are absent; ensure image picker + path provider compile SDK <=35. If still a problem, use an appropriate older compatible package version and verify API constraints from pub.dev metadata.
3. Debug `test/model_store_test.dart` hangs. Likely `ModelStore.download` awaits/stalls on stream termination or test harness setup; isolate with timeout/logging. Consider replace `MockClient` response stream with a properly closed `StreamedResponse`, or adjust implementation lifecycle.
4. `ModelStore.cancel()` presently only sets flag and closes sink; request stream may keep waiting, and cancel behavior may not satisfy cancellation. Fix using abortable request/client semantics and test interrupted/cancelled partial cleanup.
5. Once analysis/tests pass: build APK in `devenv shell`, inspect APK includes `lib/arm64-v8a/libcactus_jni.so`, install, download model in app, pick fixture/gallery, invoke app inference and capture logs/result.
6. Finish task groups 3.5, 4.x, 5.x; run airplane-mode test after download; update docs and checkboxes task-by-task per skill.

## Important files
- `cactus_pocket/lib/main.dart`
- `cactus_pocket/lib/services/{cactus_inference.dart,image_rgb.dart,model_store.dart}`
- `cactus_pocket/android/app/src/main/cpp/{CMakeLists.txt,cactus_jni.cpp,cactus.h}`
- `cactus_pocket/android/app/src/main/jni/{Android.mk,Application.mk,cactus.h}`
- `cactus_pocket/android/app/src/main/kotlin/com/cactuscompute/cactus_pocket/{MainActivity.kt,CactusNative.kt}`
- `cactus_pocket/test/{cactus_inference_test.dart,image_rgb_test.dart,model_store_test.dart,widget_test.dart}`
- `openspec/changes/mirage-android-offline-app/tasks.md`
