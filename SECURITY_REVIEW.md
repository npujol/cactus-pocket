# Security Review

**Reviewed:** 2026-11-15\
**Revision:** `f767b75` (`Archive Android build warning change`)\
**Scope:** Static review of the Flutter Android app, model-download path, gallery-image processing, Android manifest/build configuration, and JNI bridge. This is a code review, not a penetration test or a complete supply-chain audit.

## Summary

The app downloads a model over HTTPS and checks it against a pinned SHA-256 digest before promoting it to the ready-model path. Inference and image processing are local; the reviewed inference flow does not send selected images to a server. The principal concerns are release configuration and resource limits on downloaded/image data.

**Release readiness: not ready for production distribution** until the release permission/signing configuration is corrected. The resource-exhaustion and JNI validation findings should also be addressed before treating untrusted downloads or gallery images as safe inputs.

## Findings

### [Release blocker] Release variant lacks the permission required to download the model

**Evidence:** [`AndroidManifest.xml`](cactus_pocket/android/app/src/main/AndroidManifest.xml) declares no `INTERNET` permission. That permission is present only in the debug and profile manifests ([debug](cactus_pocket/android/app/src/debug/AndroidManifest.xml), [profile](cactus_pocket/android/app/src/profile/AndroidManifest.xml)). The model download uses HTTP client networking in [`model_store.dart`](cactus_pocket/lib/services/model_store.dart#L75-L80).

**Impact:** A release APK built from these manifests will not have network permission and cannot perform the initial model download. This is primarily a release-blocking configuration defect, not a vulnerability that exposes user data.

**Recommendation:** Add `android.permission.INTERNET` to the main manifest if release builds are expected to download the model. Verify the merged release manifest and test a clean install of the release variant. Keep cleartext traffic disabled; the pinned model URL uses HTTPS.

### [Release blocker] Release build is signed with the debug signing configuration

**Evidence:** [`build.gradle.kts`](cactus_pocket/android/app/build.gradle.kts#L61-L66) assigns the debug signing config to the `release` build type.

**Impact:** A release artifact is not signed with a protected, production-controlled key and must not be distributed as a production build. Anyone with access to debug signing material may be able to produce artifacts signed with the same key; consumers also cannot rely on a separately controlled release identity.

**Recommendation:** Configure a protected release signing key through CI secrets or a local, untracked properties file. Do not commit keystores or passwords. Ensure debug signing is used only for development and verify the resulting release certificate before publishing.

### [P2] Model download has no byte limit or transfer deadline

**Evidence:** [`model_store.dart`](cactus_pocket/lib/services/model_store.dart#L75-L120) streams the response to a temporary file and checks SHA-256 only after the stream finishes. It does not cap received bytes or impose a transfer timeout. The hard-coded URL and digest reduce tampering risk, but do not prevent an oversized or stalled response from consuming storage/time before verification.

**Impact:** A compromised or misbehaving upstream/redirect could cause excessive app-private storage use or a download that remains stalled. The checksum prevents an altered model from being accepted, but is not a resource limit.

**Recommendation:** Enforce a maximum download length based on the pinned artifact size, checking both `Content-Length` when present and cumulative bytes received. Apply connection/overall timeouts and preserve cleanup of partial files on every failure path.

### [P2] Gallery images are decoded and expanded without resource limits

**Evidence:** [`image_rgb.dart`](cactus_pocket/lib/services/image_rgb.dart#L19-L45) fully decodes an image, creates a second RGB image, then materializes an RGB byte buffer. [`main.dart`](cactus_pocket/lib/main.dart#L146-L154) reads the selected file wholly into memory before decoding; inference repeats the read/decode path.

**Impact:** A very large or specially crafted gallery image can cause excessive memory use, application termination, or device performance degradation. This is most relevant when users select images received from untrusted sources.

**Recommendation:** Enforce encoded-file-size and decoded-pixel limits before allocating RGB output, and downscale to a documented maximum inference size. Handle decode failures and memory pressure without crashing the app.

### [P3] JNI dimension multiplication can overflow before buffer validation

**Evidence:** [`cactus_jni.cpp`](cactus_pocket/android/app/src/main/cpp/cactus_jni.cpp#L71-L97) computes `width * height * 3` in signed `jlong`, then uses the result to validate and allocate the RGB buffer. The Kotlin bridge performs a similar unchecked `Long` multiplication in [`MainActivity.kt`](cactus_pocket/android/app/src/main/kotlin/com/cactuscompute/cactus_pocket/MainActivity.kt) (`isValidImage`).

**Impact:** Extreme, malformed dimensions can overflow the size calculation and undermine the buffer-length check, potentially leading to a native allocation/access failure. Normal gallery-driven calls use dimensions produced by the image decoder, so the practical exposure is limited to malformed bridge inputs.

**Recommendation:** Reject dimensions above explicit width, height, and pixel-count limits before multiplication. Use checked arithmetic (or division-based overflow checks) in both Kotlin and JNI, then verify the calculated byte count fits `jsize` and the actual array length.

## Positive controls observed

- The model URL is HTTPS and pinned to a repository revision; the downloaded bytes are SHA-256 checked before use ([`model_store.dart`](cactus_pocket/lib/services/model_store.dart#L7-L10), [L117-L122](cactus_pocket/lib/services/model_store.dart#L117-L122)).
- Model files are written under application support storage using a temporary `.part` file and are not considered ready unless the digest matches.
- The JNI bridge serializes access to the native inference runtime and checks basic image dimensions/byte length.
- The main manifest does not declare broad storage or camera permissions. Gallery selection uses the platform picker flow.
- Inference is described and implemented as local; the reviewed inference call passes image bytes through the Flutter/native bridge rather than to a cloud endpoint.

## Review limitations

- No dynamic penetration testing, release-manifest inspection, release-signature verification, or physical-device security testing was performed for this review.
- Third-party Dart/Android dependencies and the prebuilt native Cactus artifacts were not independently vulnerability-scanned or audited. Their correctness, provenance, and vulnerability status are outside this code-only review; retain and verify their pinned versions and checksums.
- This review does not establish regulatory compliance or guarantee absence of vulnerabilities. Re-review after material changes to networking, image decoding, native code, dependencies, or release configuration.
