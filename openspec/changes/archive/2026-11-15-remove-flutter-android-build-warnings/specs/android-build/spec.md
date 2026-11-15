# Spec Delta

## ADDED Requirements

### Requirement: Flutter-compatible Android build toolchain
The documented Flutter Android debug-build workflow MUST use toolchain versions supported by the configured Flutter SDK and complete without Flutter warnings that the Android Gradle Plugin or Kotlin Gradle Plugin is nearing end of support. The workflow MUST NOT disable Flutter's dependency-version validation to hide these warnings.

#### Scenario: Build without Flutter plugin support warnings
- **WHEN** a developer builds the debug APK using the documented devenv workflow
- **THEN** Flutter emits neither the Android Gradle Plugin nor Kotlin Gradle Plugin support warning, and dependency-version validation remains enabled
