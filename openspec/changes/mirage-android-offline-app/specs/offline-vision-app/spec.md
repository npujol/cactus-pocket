# Spec Delta

## Purpose

Let a user provide a photo to Cactus Mirage and inspect the model's scene description and structured output in a compact Flutter Android interface, including after model setup when the phone is offline.

## ADDED Requirements

### Requirement: Image input
The MVP MUST let the user select an image from the device gallery. Camera capture is out of scope for this change. Image orientation and decode failures MUST be handled explicitly.

#### Scenario: Select a gallery image
- **WHEN** the user selects a supported image
- **THEN** the app displays a preview and makes the image available for local Mirage inference

### Requirement: Inspectable Mirage result
The app MUST show the returned scene description and provide access to the raw structured response. It MUST represent loading, model download/readiness, errors and empty states clearly. Visual overlays MUST only be rendered when response schema and coordinate semantics are verified.

#### Scenario: Display inference result
- **WHEN** local inference returns a Mirage response
- **THEN** the app presents the description and lets the user inspect the structured response

### Requirement: Offline inference after setup
After the model has been downloaded and verified, image inference MUST succeed without network access, and the app MUST NOT make inference-time HTTP/cloud calls.

#### Scenario: Run inference in airplane mode
- **WHEN** the model is downloaded and verified, the app is relaunched, airplane mode is enabled, and the documented local test image is selected
- **THEN** inference completes and displays a result without network access
- **AND** verification records device/Android version, runtime/model revisions, test-image identity, model load time, inference latency, observed memory behavior and any limitations
