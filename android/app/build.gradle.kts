import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Real, not debug-signed — Play Store rejects a debug-signed
// upload outright, and a debug key isn't secret (it ships in the Flutter/
// Android SDK, identical on every machine). key.properties lives at
// android/key.properties and is gitignored — see RELEASE.md for how to
// generate the keystore it points at. Its absence doesn't fail the build:
// `flutter run`/`flutter build ... --debug` never touch this, and a release
// build with no key.properties falls back to the debug signing config so
// `flutter build apk --release` still works for local testing before you've
// created a real keystore — it just isn't Play-Store-uploadable output.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.meridian.meridian"
    // flutter.compileSdkVersion (34 as of Flutter 3.44.6) is behind what
    // transitive plugin deps now require — flutter_plugin_android_lifecycle
    // (pulled in via image_picker/file_picker) needs compileSdk >= 36.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time APIs backported to
        // API < 26 via desugaring — without this the AAR metadata check
        // fails the build before any Dart code even runs.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.meridian.meridian"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties yet — see the comment above. Fine for a
                // local `flutter build apk --release` smoke test; not fine
                // to upload anywhere.
                signingConfigs.getByName("debug")
            }
            // R8/ProGuard shrinking is deliberately NOT enabled here yet.
            // It's not Play-Store-mandatory, and this app has several
            // plugins that use reflection (drift/sqlite3, ML Kit,
            // local_auth, flutter_local_notifications, purchases_flutter) —
            // turning it on needs a tested keep-rules file per plugin
            // first, or a release build can crash in ways debug never did.
            // Worth doing before launch for a smaller download; not before
            // it's been verified against an actual release build on-device.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // On-device OCR for document capture (DocumentExtraction.kt) — the
    // bundled-model artifact, not play-services-mlkit-text-recognition,
    // so the model ships with the app rather than downloading on first use.
    // Matches the privacy contract in DocumentExtraction.swift: no network
    // call happens during a scan.
    implementation("com.google.mlkit:text-recognition:16.0.1")
}

flutter {
    source = "../.."
}
