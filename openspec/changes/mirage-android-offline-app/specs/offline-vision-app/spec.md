# Spec Delta

## Purpose

Let a user provide a photo to Cactus Mirage and inspect the model's scene description and structured output in a compact Flutter Android interface, including after model setup when the phone is offline.

## ADDED Requirements

### Requirement: Image input
The app MUST let the user select an image from the device gallery. Camera capture MAY be added after the gallery flow is validated. Image orientation and decode failures MUST be handled explicitly.

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
- **WHEN** a verified model is present and the phone is in airplane mode
- **THEN** the app can run inference on a selected local image and show its result without network access
