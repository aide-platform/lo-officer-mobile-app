import java.util.Properties
import java.io.FileInputStream
import java.security.KeyStore
import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Applied at the bottom only when android/app/google-services.json exists.
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
    id("com.google.firebase.firebase-perf") apply false
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// SHA-256 of the release signing certificate, built into the app so it can
// spot a re-signed (repackaged) APK at runtime (VAPT HIGH-05).
val releaseCertSha256: String = if (keystorePropertiesFile.exists()) {
    val store = KeyStore.getInstance(
        rootProject.file(keystoreProperties["storeFile"] as String),
        (keystoreProperties["storePassword"] as String).toCharArray(),
    )
    val cert = store.getCertificate(keystoreProperties["keyAlias"] as String)
    MessageDigest.getInstance("SHA-256").digest(cert.encoded)
        .joinToString("") { byte -> "%02X".format(byte) }
} else {
    ""
}

android {
    namespace = "com.bel.liaison_officer"
    // file_picker → flutter_plugin_android_lifecycle requires compileSdk ≥ 36
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = "28.2.13676358"

    compileOptions {
        // Required by flutter_local_notifications (Java 8+ APIs on older Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bel.liaison_officer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 10+. Android 7-9 get no security updates (VAPT LOA-03).
        minSdk = maxOf(flutter.minSdkVersion, 29)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Empty = no signature check (debug / profile builds).
        buildConfigField("String", "RELEASE_CERT_SHA256", "\"\"")
    }

    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Release builds must use the real release key (VAPT LOA-01):
            // no fallback to the shared Android Debug key. The check that
            // key.properties exists runs only when a release task is built
            // (see taskGraph below), so debug builds work without it.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            buildConfigField("String", "RELEASE_CERT_SHA256", "\"$releaseCertSha256\"")
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (buildsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties is missing. Release builds must be signed with " +
                "the release keystore (VAPT LOA-01); they no longer fall back to the " +
                "Android Debug key.",
        )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Release builds stay valid without a Firebase project. Drop a real
// google-services.json in this directory to turn the plugin on.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    apply(plugin = "com.google.firebase.firebase-perf")
}
