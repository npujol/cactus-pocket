# Spec Delta

## Purpose

Provide a reproducible Flutter Android development and deployment workflow for the project's ARM64 physical phone target using devenv, without requiring emulator system images or machine-specific SDK configuration.

## ADDED Requirements

### Requirement: Reproducible Android build environment
The project MUST configure Flutter, Java, Android SDK, build tools, and required NDK versions through the documented devenv environment. The build MUST NOT depend on an untracked, machine-specific `local.properties` path. The documented configuration MUST state how Gradle discovers SDK/NDK paths and ensure the configured NDK version is installed and writable/usable by Gradle.

#### Scenario: Build from a fresh checkout
- **WHEN** a developer enters the devenv environment and builds the Android debug APK from a fresh checkout
- **THEN** Gradle resolves SDK and NDK paths from the declared environment/configuration and produces an APK without manually editing local SDK paths

### Requirement: Physical-device workflow without emulators
The development environment MUST support building, installing, and launching on a connected ARM64 Android phone without installing emulator images or requiring an emulator.

#### Scenario: Install on connected phone
- **WHEN** an authorized ARM64 Android phone is connected through ADB
- **THEN** the documented workflow can identify the device and install/launch the debug app
