# Security Review

**Reviewed:** 2026-11-16

**Reviewed source:** GitHub `main` at `b8d7200`, with the local license-documentation update described below.

**Scope:** Follow-up static review of the Flutter Android app, model acquisition, gallery-image processing, Android build/signing configuration, Kotlin/JNI inference boundary, and GitHub source-release automation. This is not a penetration test or a complete supply-chain audit.

## Summary

The original review findings have implementation changes and host-side evidence recorded below. None is treated as fully resolved for production: no production-signed release APK or current physical-device verification was available. **Release readiness remains blocked** on production signing and target-device acceptance.

## Verification evidence

### Static and host verification

- The main manifest declares `INTERNET` and `android:usesCleartextTraffic="false"`. The merged release main manifest was generated and inspected; it contains both values.
- The release Gradle signing configuration reads four `CACTUS_RELEASE_*` environment variables and fails before packaging if they are absent. All four were unset in this environment. A release build attempt failed at the explicit signing validation task before packaging. No release APK was produced. A debug APK built successfully.
- Model-store tests cover the exact pinned byte count, oversized advertised and streamed responses, short bodies, idle and total timeouts, cancellation, cleanup, digest mismatch, and retry. The complete Flutter host test suite and analysis pass.
- Image tests cover the 32 MiB file boundary, 2048-pixel maximum side, 4-megapixel RGB-buffer boundary, invalid data, alpha compositing, and EXIF orientation. The app checks the picked file's length before reading it and validates decoder dimensions before creating RGB output. The pinned Android picker implementation's resize path was inspected: it uses bounds decoding, sampled bitmap decoding, and EXIF copying. The app requests 2048-by-2048 limits.
- Kotlin unit tests and a host-compiled C++ validation test cover zero, negative, over-limit, mismatched, extreme, and valid boundary dimensions. The debug build compiles the JNI library; both validators gate the inference call before image-buffer allocation/copy.
- `devenv shell -- prek run --all-files` passes. `devenv shell -- test-solution` passes analysis, Flutter tests, debug APK packaging, and ARM64 JNI packaging, then exits 2 because no authorized ADB device is attached.

### Source-publication checks

- Before adding release automation, tracked source and reachable Git history were checked for private-key blocks and common credential/token patterns; no matches were found. The new workflow/config were separately inspected and contain only a reference to GitHub's built-in token, not a token value.
- `local.properties` is ignored and untracked. No keystore, signing-property file, or release credential is tracked.
- This was a targeted pattern scan, not an exhaustive secret audit. No dedicated secret-scanning tool was run, and the result does not guarantee that all sensitive data is absent.
- The semantic-release workflow creates GitHub source releases only; it does not build or upload APKs. It grants `contents: write`, uses commit-pinned GitHub Actions, and relies on the built-in `GITHUB_TOKEN`; no custom token or signing secret was added.
- `npm audit --omit=dev` reports no production dependencies. The full audit reports 36 moderate advisories in the release-tooling dependency tree and no high-severity advisories at review time. These development dependencies execute in the release workflow, so the findings remain relevant and should be rechecked before release.
- `npm ci`, semantic-release CLI loading, configuration parsing, the Flutter version-code mapping test, and `actionlint` pass. GitHub Actions run `43959751908` completed successfully and created source release `v1.0.0`; no APK was built or uploaded.
- The root MIT `LICENSE` is preserved for project-authored code. This update adds `LICENSES/Apache-2.0.txt` from the pinned Cactus 4.1.1 upstream license and `THIRD_PARTY_NOTICES.md` with runtime/model provenance, checksums, and license metadata. The pinned upstream trees were checked and contain no `NOTICE` file.
- The existing `v1.0.0` source release predates these added license files and is unchanged. A later source release is needed for its downloadable archive to include the notices.

### Release-artifact and device verification not performed

- No production signing secrets are available. No release APK was created, and no release certificate or release APK manifest was inspected.
- `adb devices -l` lists no device. No current-device gallery selection, model download, timeout/size failure interaction, inference, airplane-mode run, or recoverable UI flow was exercised.
- The README contains earlier device-acceptance evidence for the prior worktree; it does not verify the newly added size limits, timeout handling, image boundaries, or JNI checks on a device.

## Findings and current status

### [Release configuration] Network permission and cleartext policy

**Status:** Implemented; merged-manifest verification passed. Release APK/device download behavior remains unverified.

**Evidence:** [`AndroidManifest.xml`](cactus_pocket/android/app/src/main/AndroidManifest.xml) declares `INTERNET` and disables cleartext traffic. The generated release merged manifest contains the permission and `usesCleartextTraffic="false"`. The pinned model URL is HTTPS, and [`model_store.dart`](cactus_pocket/lib/services/model_store.dart) rejects a non-HTTPS final response URL.

### [Release configuration] Production-controlled release signing

**Status:** Fail-closed configuration and debug signing verified; production release identity remains unverified.

**Evidence:** [`build.gradle.kts`](cactus_pocket/android/app/build.gradle.kts) uses externally supplied store path, store password, alias, and key password. The keystore must be readable and outside the repository. With all four variables absent, `flutter build apk --release` fails at `validateReleaseSigning` before packaging; no release APK was produced. `flutter build apk --debug` succeeds. No keystore or signing-property file is tracked.

**Limitation:** No protected production key is available here. Do not distribute a release artifact until it is built with the production key and its certificate is verified.

### [P2] Bounded model acquisition

**Status:** Implementation and host tests verified; on-device timeout/retry behavior remains unverified.

**Evidence:** [`model_store.dart`](cactus_pocket/lib/services/model_store.dart) caps writes at 21,611,043 bytes, requires the exact pinned byte count and SHA-256, applies a 10-minute total deadline and 60-second idle timeout, aborts requests on timeout, distinguishes timeout errors from user cancellation, and removes partial files on failure. Model-store tests exercise the negative paths and retry.

### [P2] Resource-bounded gallery image processing

**Status:** Implementation and host tests verified; physical gallery behavior remains unverified.

**Evidence:** [`main.dart`](cactus_pocket/lib/main.dart) requests 2048-by-2048 picker output and calls `readBoundedImageFile` before reading image bytes. [`image_rgb.dart`](cactus_pocket/lib/services/image_rgb.dart) limits encoded files to 32 MiB, inspects dimensions before pixel decoding, rejects dimensions above 2048 per side or 4 megapixels, and checks the RGB byte-count/cap before returning inference input. Invalid selections clear the prior preview and inference-ready selection, with a recoverable user-facing error. Host tests cover file and dimension boundaries, alpha, orientation, and RGB size.

### [P3] Kotlin/JNI image validation

**Status:** Implementation, host unit tests, and JNI compilation verified; on-device inference behavior remains unverified.

**Evidence:** [`ImageInputLimits.kt`](cactus_pocket/android/app/src/main/kotlin/com/cactuscompute/cactus_pocket/ImageInputLimits.kt) and [`image_input_limits.h`](cactus_pocket/android/app/src/main/cpp/image_input_limits.h) enforce matching positive-dimension, 2048-side, 4-megapixel, and exact `width * height * 3` constraints with guarded arithmetic. `MainActivity` gates dispatch before scheduling native inference. JNI runs the shared native validation gate before allocating/copying the RGB buffer and before calling `cactus_describe`. Kotlin and native tests verify invalid inputs do not invoke the gated callback and valid maximum dimensions are accepted.

## Positive controls observed

- The pinned model URL and its final response URL must be HTTPS; cleartext traffic is disabled in the main Android manifest.
- The model is promoted only after exact-size and pinned SHA-256 checks; failed downloads remove the `.part` file.
- Gallery processing is local. Selected images are not sent to a cloud inference endpoint.
- Image RGB allocation and native buffer copying are bounded by the same 2048-side/4-megapixel policy.
- The main manifest does not declare broad storage or camera permissions; gallery selection uses the platform picker.

## Review limitations

- No dynamic penetration testing, production-signed release-artifact inspection, or current physical-device security testing was performed.
- Third-party Dart/Android dependencies and the prebuilt Cactus archive were not independently vulnerability-scanned or audited. Their correctness, provenance, and vulnerability status are outside this code review; retain and verify pinned versions and checksums.
- Host-side tests do not establish peak memory use, device stability at image boundaries, successful release networking, production certificate identity, or offline inference on the current app build.
- Re-review after material changes to networking, image decoding, native code, dependencies, signing, or release configuration.
