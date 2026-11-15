# Spec Delta

## ADDED Requirements

### Requirement: Bounded model acquisition
Model acquisition MUST NOT write more than the pinned model artifact's declared size (currently 21,611,043 bytes), regardless of response headers. A download MUST have a finite overall deadline and idle timeout, and MUST be accepted only after the existing pinned SHA-256 check succeeds.

#### Scenario: Reject oversized or stalled model responses
- **WHEN** a model response exceeds the pinned size limit or exceeds a download deadline
- **THEN** the request fails recoverably, the temporary file is removed, and no model is promoted or loaded

#### Scenario: Accept the pinned model within limits
- **WHEN** the complete pinned model is received within the size and time limits
- **THEN** it is promoted only after its exact pinned SHA-256 digest is verified

### Requirement: Overflow-safe native image validation
The native inference boundary MUST reject non-positive, over-limit, overflowing, or byte-count-mismatched image dimensions before allocating or copying an image buffer. Dimension and byte-count calculations MUST be overflow-safe in both the platform bridge and JNI.

#### Scenario: Reject malformed native image dimensions
- **WHEN** a bridge request contains extreme dimensions or an RGB buffer whose size does not match the dimensions
- **THEN** the request returns a recoverable validation error before native image allocation or inference
