# Tasks

## 1. Secure release configuration

- [x] 1.1 Add `INTERNET` permission and explicit cleartext denial to the main Android manifest; verify the merged release manifest contains the permission and disallows cleartext HTTP.
- [x] 1.2 Replace release debug-key signing with required externally supplied release credentials and fail the release build when credentials are absent; verify debug builds still build and no credentials are tracked.
- [x] 1.3 Document release credential provisioning and the release network policy in the README; verify documented commands/settings match the Gradle configuration.

## 2. Bound model acquisition

- [x] 2.1 Add the 21,611,043-byte cap, exact expected byte count, 10-minute total deadline, and 60-second idle timeout; abort timed-out requests distinctly from user cancellation and preserve partial-file cleanup/retry.
- [x] 2.2 Extend `model_store_test.dart` for oversized advertised/streamed bodies, short bodies, stalled and timed-out responses, cancellation, cleanup, digest verification, and successful retry; verify no failed path promotes or loads a model.
- [x] 2.3 Document model size and timeout behavior with recovery guidance; verify docs identify that model size and digest must be updated together when pinning a new artifact.

## 3. Bound gallery image processing

- [x] 3.1 Request a 2048-by-2048 maximum from the Android gallery picker, check returned file size before reading into Dart, and reject unsafe dimensions before RGB allocation; verify selected images retain EXIF orientation and alpha handling.
- [x] 3.2 Extend image tests for 32 MiB file-size and 2048-side/4-megapixel boundaries, downsampled output, unsupported/unsafe dimensions, and recoverable errors; verify all accepted buffers obey the RGB size formula and cap.
- [x] 3.3 Document supported image limits and the user-visible oversized-image recovery path; verify UI errors are clear and do not leave a selected image in a misleading inference-ready state.

## 4. Harden Kotlin and JNI image validation

- [x] 4.1 Add matching dimension/pixel limits and overflow-safe RGB byte-count validation in the Kotlin bridge and JNI before native buffer allocation/copy; verify Kotlin and native checks reject the same invalid inputs.
- [x] 4.2 Add focused tests for zero, negative, over-limit, mismatched, and extreme dimensions; verify rejection happens before the native inference API is invoked and valid boundary buffers are accepted.

## 5. End-to-end release verification and review evidence

- [ ] 5.1 Run `devenv shell -- test-solution` and `devenv shell -- prek run --all-files`; verify analysis, tests, debug APK packaging, and the existing device workflow pass.
- [ ] 5.2 Build a signed release APK with production credentials; inspect its merged manifest, ABI, and signing certificate. Install it on an ARM64 device from a clean install. Verify first launch, online model download, ready status after force-stop/relaunch, gallery inference, and fresh inference after another relaunch in airplane mode. Record the APK version, certificate, device, and results. A green source-release workflow does not count as app verification; it publishes no APK. Do not build or publish an artifact if release credentials are unavailable.
- [ ] 5.3 Exercise download-size/timeout failures and image-size boundaries, including recoverable UI behavior; verify partial downloads are removed and inference still works offline with a valid image/model.
- [x] 5.4 Update `SECURITY_REVIEW.md` with only verified results, unresolved limitations, and clear distinctions between static review and device/release-artifact evidence; verify no finding is marked resolved without supporting evidence.
