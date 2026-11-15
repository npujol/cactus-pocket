# Proposal

## Why

A static security review found release configuration blockers and missing resource bounds around model downloads, gallery-image decoding, and JNI dimension validation. These gaps can prevent model setup in a release APK or let oversized/malformed inputs consume excessive resources, so close them before production distribution.

## What Changes

- Include the network permission required for the release model download while retaining HTTPS-only networking.
- Separate release signing from the debug key; keep production signing credentials outside the repository and verify release artifacts use the configured release certificate.
- Bound the pinned model download by artifact size and transfer deadlines, preserving checksum verification, cancellation, cleanup, and retry behavior.
- Apply documented encoded-image, decoded-pixel, and inference-dimension limits before large allocations; provide a clear recoverable error for images that exceed supported limits.
- Use overflow-safe dimension and byte-count validation at both the Kotlin bridge and JNI boundary.
- Add focused boundary/failure tests and update the security review with verification results and remaining limitations.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `android-build`: Specify release manifest network configuration and production-controlled release signing in addition to the existing development build workflow.
- `mirage-inference`: Require bounded, integrity-checked model acquisition and overflow-safe native image buffer validation.
- `offline-vision-app`: Require resource-bounded gallery image handling with clear recovery for unsupported oversized inputs.

## Impact

- Android manifest and Gradle release signing configuration.
- Dart model download/storage service and its tests.
- Gallery image decoding and RGB conversion, Flutter error presentation, and image tests.
- Kotlin MethodChannel validation and JNI dimension/buffer validation.
- Release artifact verification and `SECURITY_REVIEW.md` evidence.
