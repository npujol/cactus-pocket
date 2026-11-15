# Design

## Context

See `proposal.md` for the motivation and scope. The configured Flutter SDK is 3.47.4; `settings.gradle.kts` pins AGP 8.11.1 and Kotlin Gradle Plugin 2.2.20. The Gradle wrapper is 9.3.1, Java is 17, compile/target SDK is 35, and the Android app packages an NDK-built ARM64 JNI library. The current SDK is immutable and declares Build Tools 35.0.0. The app pins `image_picker_android` 0.8.12+2, which compiles against API 34, while its lifecycle dependency requires API 35. `gradle.properties` sets `android.builtInKotlin=false` and `android.newDsl=false`; preserve these flags unless testing shows they must change.

## Goals / Non-Goals

**Goals:**
- Use an Android Gradle/Kotlin toolchain accepted by the configured Flutter SDK and eliminate its two reported support warnings.
- Preserve the devenv-driven, ARM64 APK build and device workflow.
- Keep Flutter's dependency-version validation enabled.

**Non-Goals:**
- Eliminate unrelated Gradle, Flutter, Kotlin, Dart, or lint warnings.
- Change the app's runtime behavior, target API, native inference code, or model artifacts.
- Upgrade Flutter itself or change the Android SDK/NDK unless compatibility proves it necessary.

## Decisions

1. **Use Flutter's stated minimums as the initial target.** The reported SDK asks for at least AGP 9.0.1 and Kotlin 2.3.20. Select versions at or above those values after checking their mutual compatibility with Gradle 9.3.1, Java 17, and Flutter 3.47.4. Prefer the lowest compatible versions to limit unrelated migration surface. Alternatives are to retain older plugins and suppress the warning, which violates the requirement, or upgrade Flutter, which expands scope.
2. **Treat AGP 9 configuration migration as a compatibility check, not an assumption.** Verify whether AGP's built-in Kotlin/new DSL behavior requires changing `android.builtInKotlin=false`, `android.newDsl=false`, or plugin application in the Android project. Make only the changes required for the selected supported combination; do not disable Flutter's version validation. If the minimum versions cannot coexist with the current project setup, select the nearest supported combination and document why.
3. **Preserve runtime targeting while meeting compile-time requirements.** Keep Java 17, target SDK 35, pinned NDK 28.2.13676358, ARM64-only native packaging, and the existing devenv/ADB workflow. AGP 9.0.1 requires Build Tools 36.0.0, and `image_picker_android` 0.8.13+1 requires SDK Platform 36; add both packages to the immutable devenv SDK and set app compileSdk to 36. Raising compileSdk does not opt the app into API 36 runtime behavior; targetSdk remains 35.
4. **Align the image-picker Android module with its lifecycle dependency.** Upgrade the exact `image_picker_android` pin from 0.8.12+2 to 0.8.13+1. The cached package supports the current Flutter/Dart SDK and uses `flutter.compileSdkVersion`, unlike the pinned 0.8.12+2 module compiled against API 34. Keep `image_picker` 1.1.2 and `flutter_plugin_android_lifecycle` 2.0.26 unchanged. Verify dependency resolution, tests, and gallery selection on the phone.
5. **Verify through the project's existing validation path.** Run `devenv shell -- test-solution` to cover analysis, Dart tests, debug APK assembly, ARM64 JNI presence, and connected-device install/launch. Capture build output and confirm the two named Flutter warnings are absent; do not treat unrelated warnings as failures for this requirement.

## Risks / Trade-offs

- **AGP 9 changes Kotlin or DSL integration** -> Check Flutter's and AGP's migration guidance before changing flags; test from a clean Gradle state and preserve a reversible, focused version/configuration diff.
- **AGP 9 or the picker requires newer Android SDK components** -> Declare Build Tools 36.0.0 and Platform 36 in devenv; keep targetSdk 35 and verify the build does not require a runtime-targeting change.
- **The image-picker Android update changes device behavior** -> Run Flutter tests and manually select a gallery image on the connected device, confirming the app preview still works.
- **A newer plugin combination affects native packaging or device builds** -> Verify the APK still contains `lib/arm64-v8a/libcactus_jni.so` and run the existing physical-device check.
- **Flutter's warning threshold changes later** -> Keep versions explicit and use the actual configured Flutter SDK's build output as the acceptance signal; future Flutter upgrades may require another deliberate toolchain update.

## Migration Plan

Update the Android plugin pins, Build Tools and Platform declarations, app compileSdk, and image-picker Android package pin/lockfile, changing Gradle wrapper/project flags only if required. Keep targetSdk at 35. Run the full existing validation and device workflow, including gallery selection. If the build or device check regresses, revert the Android toolchain and picker dependency changes as a unit; this restores the prior build setup but also restores the warnings.
