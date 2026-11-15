# Spec Delta

## Purpose

Run the pinned Cactus Mirage model through the dedicated native Android `cactus_describe` API and provide safe, explicit model and inference operations to the Flutter app.

## ADDED Requirements

### Requirement: Pinned compatible native runtime
The app MUST use a documented, pinned Cactus Android runtime and Mirage model revision whose native API supports `cactus_describe` for the target ARM64 ABI. It MUST NOT use the command-line runner's nonexistent image option as the inference interface.

#### Scenario: Verify runtime compatibility
- **WHEN** the app initializes Mirage
- **THEN** it loads the pinned model using the selected Android runtime and reports actionable native errors if the runtime/API/model is incompatible

### Requirement: App-private model availability
The app MUST store the Mirage model in app-private persistent storage and expose whether it is absent, downloading, verifying, ready, or failed. Downloads MUST be cancellable/retryable and integrity-checked against a pinned checksum before the model is loaded.

#### Scenario: Prepare model once
- **WHEN** the user downloads the model while connected
- **THEN** the app saves and verifies it in app-private storage and reports ready state for subsequent launches

#### Scenario: Reject invalid model
- **WHEN** the downloaded model fails its checksum or cannot be stored
- **THEN** the app MUST NOT load it and MUST explain the failure with a retry/recovery path

### Requirement: Local image inference
The app MUST decode an image to correctly oriented packed RGB pixels and invoke the native `cactus_describe` API locally with its dimensions and supported options. Native work MUST not block the Flutter UI thread, and native resources MUST be released safely.

#### Scenario: Describe an image on device
- **WHEN** the model is ready and the user requests inference for a supported image
- **THEN** the native bridge returns the raw Mirage response or a structured actionable error without requiring a network connection

### Requirement: Explicit inference lifecycle and errors
The app MUST expose load/inference progress or busy state, prevent unsafe overlapping native calls, and surface recoverable model/runtime/image errors without silently attempting network access.

#### Scenario: Inference fails
- **WHEN** model loading or `cactus_describe` fails
- **THEN** the app displays an actionable error and remains in a safe state for retry or recovery
