plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val buildCactusNative by tasks.registering(Exec::class) {
    val ndkRoot = System.getenv("ANDROID_NDK_ROOT") ?: error("ANDROID_NDK_ROOT is required in devenv")
    val jniDir = layout.projectDirectory.dir("src/main/jni").asFile
    val jniLibsDir = layout.projectDirectory.dir("src/main/jniLibs").asFile
    inputs.files(fileTree("src/main/jni"), fileTree("src/main/cpp"), fileTree("src/main/native-libs"))
    outputs.file(jniLibsDir.resolve("arm64-v8a/libcactus_jni.so"))
    doFirst {
        jniLibsDir.mkdirs()
        commandLine(
            "$ndkRoot/ndk-build",
            "NDK_PROJECT_PATH=.",
            "APP_BUILD_SCRIPT=Android.mk",
            "NDK_APPLICATION_MK=Application.mk",
            "NDK_LIBS_OUT=${jniLibsDir.absolutePath}",
            "NDK_OUT=${layout.buildDirectory.dir("ndk").get().asFile.absolutePath}",
            "-j4",
        )
        workingDir = jniDir
    }
}

tasks.configureEach {
    if (name.startsWith("pre") && name.endsWith("Build")) dependsOn(buildCactusNative)
}

android {
    namespace = "com.cactuscompute.cactus_pocket"
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cactuscompute.cactus_pocket"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
