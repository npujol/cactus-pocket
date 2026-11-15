# Spec Delta

## ADDED Requirements

### Requirement: Resource-bounded gallery images
The app MUST enforce a 32 MiB encoded-file limit before reading an image into Dart memory. It MUST inspect dimensions and use a bounded decode/downsample path so pixel allocations and inference input are at most 2048 pixels on either side and 4 megapixels total. If dimensions cannot be safely inspected or bounded, the app MUST reject the image with a clear recoverable error.

#### Scenario: Process an image within supported limits
- **WHEN** the user selects a supported image within the encoded-file limit
- **THEN** the app bounds decoded inference pixels to the documented maximum and makes the image available for local inference

#### Scenario: Reject an image exceeding resource limits
- **WHEN** the user selects an image exceeding the encoded-file limit or whose dimensions cannot be safely bounded
- **THEN** the app rejects it before unbounded pixel allocation and reports a recoverable, user-readable error
