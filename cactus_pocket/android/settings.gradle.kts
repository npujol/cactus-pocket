pluginManagement {
    val flutterSdkPath =
        System.getenv("FLUTTER_ROOT")
            ?: run {
                val properties = java.util.Properties()
                val localProperties = file("local.properties")
                if (localProperties.exists()) {
                    localProperties.inputStream().use { properties.load(it) }
                }
                properties.getProperty("flutter.sdk")
                    ?: error("Set FLUTTER_ROOT or flutter.sdk in local.properties")
            }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
