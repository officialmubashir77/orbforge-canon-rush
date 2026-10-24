# Android CI build reference

- **Godot editor:** Godot 4.7.2 Stable, official `Godot_v4.7.2-stable_linux.x86_64.zip`.
- **Templates:** matching official `Godot_v4.7.2-stable_export_templates.tpz`.
- **JDK:** Eclipse Temurin 17 (`actions/setup-java@v4`).
- **Android SDK:** build-tools 35.0.1, platform 35, platform-tools, cmdline-tools latest; NDK 28.1.13356709 and CMake 3.10.2.4988404 as prescribed in the Godot 4.7 docs.
- **CI operating system:** `ubuntu-24.04` (GitHub-hosted).
- **Source runner check:** `python3 tools/validate_project.py`.
- **Godot runner tests:** `godot --headless --path . --script res://tests/test_runner.gd`.
- **APK export:** `godot --headless --path . --export-debug "Android" builds/orbforge-debug.apk`.
- **Release:** manual or v* tag. Use `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables and Gradle template for AAB.

Reference: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

**First GitHub run remains necessary:** No headless Godot editor / Android SDK binary was accessible during source creation. Failing steps should be handled as defects, never marked passing by hand.
