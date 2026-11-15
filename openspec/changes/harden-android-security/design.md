# Design

## Context

See `proposal.md` for motivation and the three spec deltas for required behavior. The current app already pins the model URL and digest, stores to a temporary file, and supports cancellation, but does not cap the downloaded bytes or bound transfer time. Gallery handling reads the selected file into Dart memory and fully decodes it before creating a second RGB buffer. Kotlin and JNI check dimensions but multiply them without explicit limits or overflow-safe guards. The main manifest lacks network permission, and the release build currently selects the debug signing config.

The app targets Android only. Its pinned image-picker Android implementation supports max-width/max-height resizing using Android bitmap bounds inspection and sampled decoding; validate its returned file rather than treating plugin parameters as the only safeguard. The pinned Mirage artifact is 21,611,043 bytes.

## Goals / Non-Goals

**Goals:**
- Make release networking functional while refusing cleartext traffic, and make production signing explicit and fail-closed.
- Bound acquisition and image processing before large writes, reads, copies, or native allocations.
- Preserve pinned-digest verification, offline inference, retry/cancel behavior, and common gallery-image support.
- Verify boundary cases in tests and verify merged release manifest/signing metadata.

**Non-Goals:**
- Rotate an already-issued signing key or create/commit signing credentials.
- Add a cloud inference path, new image formats, or new runtime/model artifacts.
- Perform a full dependency/native-binary audit or claim a penetration test.

## Decisions

1. **Declare release networking in the main manifest and explicitly disable cleartext.** Keep the pinned HTTPS source and require the final response URL to remain HTTPS if redirects are followed. The `INTERNET` permission is required by release model acquisition; relying on debug/profile manifest permissions is incorrect. Do not add storage, camera, or other permissions.

2. **Require externally supplied release signing credentials.** Keep debug builds on the debug key. Configure the release keystore/alias/password through the release environment (for example, CI secrets or untracked local properties), and make a release build fail if those values are missing. Do not silently fall back to debug signing. The exact secret names can follow existing CI conventions; no credential is available in this planning environment.

3. **Treat the pinned model size as a hard limit.** Use 21,611,043 bytes as the maximum received length; reject an advertised content length above the limit and stop streaming as soon as cumulative bytes exceed it. Require the final byte count to match the pinned artifact size and retain the SHA-256 check as the authenticity/integrity gate. Use a 10-minute total deadline and a 60-second no-progress deadline. Timeouts must abort the request/stream, remain distinguishable from user cancellation, remove `.part`, and allow retry. Keep the limits coupled to the pinned artifact metadata so future model upgrades must update size and digest together.

4. **Downsample at selection, then enforce postconditions before Dart allocation.** Request a 2048-by-2048 maximum from the existing Android picker, which samples during bitmap decode. Before reading the returned file into Dart, check it is at most 32 MiB. Validate dimensions and pixel count before constructing RGB output or invoking inference; reject if picker output exceeds 2048 on either side or 4 megapixels. Do not add another decoder dependency unless the existing picker/decoder cannot uphold bounded allocation. Return an actionable error for files the picker cannot safely resize/decode. Keep EXIF orientation and alpha handling unchanged, then verify the decoded output respects the same limits.

5. **Use a shared validation policy at every trust boundary.** Keep the same 2048-per-side/4-megapixel limit in Dart, Kotlin, and JNI. Reject dimensions above limits before multiplication; use checked or division-guarded arithmetic, verify the computed RGB byte count equals the supplied array length, and verify it fits JNI array/index types before copying to native memory. JNI repeats validation rather than relying solely on the Flutter/Kotlin caller.

6. **Test negative paths and prove release properties from built artifacts.** Extend Dart fake-client tests for oversized headers/chunks, short/mismatched models, stalls, deadlines, abort, cleanup, and retry. Extend image tests for file-size and dimensions at/beyond boundaries, RGB output bounds, and readable errors. Exercise the Kotlin/JNI validation boundary with zero, negative, over-limit, mismatched, and extreme dimensions without calling inference for rejected inputs. Build the release variant in an environment with configured secrets, inspect the merged manifest for Internet permission and cleartext denial, and use Android signing tools to confirm the APK certificate is the configured release certificate and differs from debug.

7. **Keep the security review evidence-based.** Update `SECURITY_REVIEW.md` only after each control is implemented and verified. Mark static review versus release artifact/device evidence distinctly; do not state that signing, release networking, or large-input safety passed without the corresponding evidence.

## Risks / Trade-offs

- [Very slow or intermittent networks can exceed the download deadlines] → The download is user-triggered, can be cancelled, and can be retried; tests must verify cleanup and distinguish timeout from cancellation.
- [The image picker may return an unchanged file for unsupported or unusual formats] → Check file size and decoded dimensions after selection; reject safely rather than falling back to an unbounded decode.
- [Debug/release behavior differs after fail-closed signing] → Keep debug signing unchanged and verify the normal debug workflow; document that release builds require externally provisioned signing secrets.
- [Artifact size may change with a model revision] → Make model size part of the pinned-artifact update checklist and test the exact expected byte count with the digest.
- [The existing device memory evidence is a post-inference snapshot, not a peak measurement] → Exercise boundary images on the target ARM64 phone and record observed memory/failure behavior without claiming a universal memory guarantee.

## Migration Plan

1. Add main-manifest network policy and configure release signing inputs; confirm debug build/install remains unchanged.
2. Implement and test bounded model download and bounded image conversion, then add duplicated Kotlin/JNI validation.
3. Build a release APK only in an environment provisioned with the release key; inspect merged manifest and signature. Do not publish an artifact signed with a debug or temporary key.
4. Run the project checks and target-device image/download regression tests. Update `SECURITY_REVIEW.md` with observed evidence and unresolved limitations.
5. Roll back by reverting the change if verification fails. Do not replace the protected release key as a rollback mechanism; previously distributed signing identity must remain stable.

## Open Questions

_None._
