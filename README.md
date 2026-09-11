# BlueEra

## Local setup

Some files are intentionally **not** committed because their contents differ per
machine. After cloning (or after pulling a change that removes them), create them:

```bash
cp android/local.properties.example android/local.properties
# then edit it and set sdk.dir, flutter.sdk and MAP_API_KEY for your machine
```

### Pinning a JDK

AGP 8.13 requires **Java 17**. Android Studio bundles a newer JVM that Gradle
will reject, so if `flutter build` fails with an invalid/unsupported Java home,
pin the JDK per-machine — never in the committed `android/gradle.properties`:

```properties
# ~/.gradle/gradle.properties   (outside the repo, so it can't be committed)
org.gradle.java.home=C:/Program Files/Java/jdk-17     # Windows
# org.gradle.java.home=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home   # macOS
```

Setting `JAVA_HOME` to a JDK 17 install works too. `android/local.properties`
does *not* work for this — Gradle never reads that file for its own properties.

## Build

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Hive adapters + envied
flutter build appbundle --release
```

---

## Reference environment

A known-good toolchain (from `flutter doctor`):

```
Android Studio Otter 2 Feature Drop | 2025.2.2
Build #AI-252.27397.103.2522.14514259, built on December 1, 2025
Runtime version: 21.0.8+-14196175-b1038.72 aarch64

Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.38.7, on macOS 26.3.1 25D771280a darwin-arm64, locale en-IN)
[✓] Android toolchain - develop for Android devices (Android SDK version 36.1.0-rc1)
[✓] Xcode - develop for iOS and macOS (Xcode 26.2)
[✓] Chrome - develop for the web
[✓] Connected device (3 available)
[✓] Network resources

• No issues found!


be.beapp.in```
