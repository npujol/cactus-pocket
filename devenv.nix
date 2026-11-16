{pkgs, ...}: {
  packages = with pkgs; [
    android-tools
    git
    curl
    prek
    ktlint
    detekt
  ];

  languages.java.enable = true;
  languages.java.jdk.package = pkgs.jdk17;
  android.flutter.enable = true;

  git-hooks = {
    enable = true;
    package = pkgs.prek;
    configPath = ".pre-commit-config.yaml";
    hooks = {};
  };

  scripts.test-flutter-linux.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT/cactus_pocket"
    flutter analyze --no-fatal-infos
    flutter test
    bash tool/test_native_image_limits.sh
  '';

  scripts.test-solution.exec = ''
    set -euo pipefail
    test-flutter-linux
    cd "$DEVENV_ROOT/cactus_pocket"
    flutter build apk --debug

    apk="build/app/outputs/flutter-apk/app-debug.apk"
    test -f "$apk"
    unzip -Z1 "$apk" | grep -Fx 'lib/arm64-v8a/libcactus_jni.so' >/dev/null

    device="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
    if [ -z "$device" ]; then
      echo "No authorized ADB device connected; APK built and ARM64 JNI checked, device test skipped." >&2
      exit 2
    fi

    adb -s "$device" install -r "$apk"
    adb -s "$device" shell monkey -p com.cactuscompute.cactus_pocket 1
    sleep 3
    if ! adb -s "$device" shell pidof com.cactuscompute.cactus_pocket >/dev/null; then
      echo "App process did not remain alive after launch on $device." >&2
      adb -s "$device" logcat -d -t 300 | grep -i 'cactus_pocket\|FATAL EXCEPTION' | tail -80 >&2 || true
      exit 1
    fi
    echo "Build, APK ABI check, install, and launch verified on $device. Complete the app's online download/inference checks, then repeat in airplane mode."
  '';

  # Keep Android integration SDK narrow: a single compile platform, build-tools
  # and platform-tools. No emulator packages or system images.
  android = {
    enable = true;
    platforms.version = ["34" "35" "36"];
    buildTools.version = ["36.0.0"];
    platformTools.version = "latest";
    emulator.enable = false;
    systemImageTypes = [];
    # Bundle the pinned NDK into the immutable SDK so Gradle never tries to
    # install it with sdkmanager during a build.
    ndk.enable = true;
    cmake.version = ["3.22.1"];
    googleAPIs.enable = false;
    ndk.version = ["28.2.13676358"];
    # Only ARM64 phones are in the MVP target.
    abis = ["arm64-v8a"];
  };

  scripts.android-doctor.exec = ''
    echo "Flutter:"; flutter --version
    echo "Java:"; java -version
    echo "Android SDK: $ANDROID_HOME"
    if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
      ls "$ANDROID_HOME"
    else
      echo "SDK path is configured by devenv's Android integration"
    fi
    echo "Connected devices:"; adb devices
  '';

  enterShell = ''
    echo "Cactus Pocket dev shell"
    echo "Run 'android-doctor' to check Flutter, Java, Android SDK and devices."
  '';
}
