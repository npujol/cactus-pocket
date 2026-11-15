# mirage-inference Specification

## Purpose

Run a verified Cactus Mirage model through the dedicated native Android `cactus_describe` API and provide safe, explicit model and inference operations to the Flutter app.

## Requirements

### Requirement: Verified and pinned native runtime
Before native integration is selected, the change MUST record a specific Cactus Android ARM64 runtime artifact and Mirage model revision, their source URLs, versions/revisions, ABI, sizes and applicable licenses/redistribution terms. It MUST record the exact verified API declarations, error convention, buffer ownership/lifetime and model-loading behavior for `cactus_load`, `cactus_models`, `cactus_last_error`, and `cactus_describe`. The app MUST use a compatible pinned pair that exports the dedicated `cactus_describe` API. It MUST NOT use the command-line runner's nonexistent image option as the inference interface. If compatibility or licensing cannot be established, native integration MUST stop and the blocker must be documented.

#### Scenario: Verify runtime compatibility before integration
- **WHEN** the runtime and model are investigated
- **THEN** evidence establishes the selected ARM64 artifact, API contract, model compatibility and usage terms before the native bridge is implemented

#### Scenario: Initialize Mirage
- **WHEN** the app initializes Mirage
- **THEN** it loads the pinned model using the selected Android runtime and reports actionable native errors if the runtime/API/model is incompatible

### Requirement: App-private model availability
The app MUST store the Mirage model in app-private persistent storage and expose whether it is absent, downloading, verifying, ready, or failed. Downloads MUST use a pinned HTTPS source and be integrity-checked against a pinned SHA-256 before the model is loaded. Cancellation, process interruption, checksum failure, and storage failure MUST leave no partial file eligible for loading and MUST allow a safe retry or recovery path.

#### Scenario: Prepare model once
- **WHEN** the user downloads the model while connected
- **THEN** the app saves and verifies it in app-private storage and reports ready state for subsequent launches

#### Scenario: Cancel or interrupt a download
- **WHEN** the user cancels a download or the process/network stops before completion
- **THEN** any partial artifact is discarded or isolated from the ready-model path, and a later retry starts safely

#### Scenario: Reject invalid model
- **WHEN** the downloaded model fails its checksum or cannot be stored
- **THEN** the app MUST NOT load it and MUST explain the failure with a retry/recovery path

### Requirement: Local image inference
The app MUST decode an image to correctly oriented packed RGB pixels and invoke the native `cactus_describe` API locally with its dimensions and supported options. Native work MUST not block the Flutter UI thread, and native resources MUST be released according to the verified API ownership contract.

#### Scenario: Describe an image on device
- **WHEN** the model is ready and the user requests inference for a supported image
- **THEN** the native bridge returns the raw Mirage response or a structured actionable error without requiring a network connection

### Requirement: Explicit inference lifecycle and errors
The app MUST expose load/inference progress or busy state, prevent unsafe overlapping native calls, and surface recoverable model/runtime/image errors without silently attempting network access.

#### Scenario: Inference fails
- **WHEN** model loading or `cactus_describe` fails
- **THEN** the app displays an actionable error and remains in a safe state for retry or recovery
