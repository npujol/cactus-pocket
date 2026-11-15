# Spec Delta

## ADDED Requirements

### Requirement: Secure release network configuration
The release application MUST have the network permission needed to download the pinned model, and MUST reject cleartext HTTP connections. Model acquisition MUST continue to use HTTPS.

#### Scenario: Download the model in a release build
- **WHEN** a user installs a release build and downloads the pinned model over a valid HTTPS connection
- **THEN** the app has the required network permission and completes the download without permitting cleartext HTTP

### Requirement: Production-controlled release signing
A distributable release artifact MUST be signed with a configured production release key distinct from the development debug key. Release signing credentials MUST NOT be committed to the repository.

#### Scenario: Verify a release artifact signature
- **WHEN** a release artifact is built for distribution
- **THEN** its signing certificate matches the configured release certificate and differs from the debug certificate, with no signing secret present in tracked source
