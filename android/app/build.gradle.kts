import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val dartEnvironmentVariables = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    val rawDefines = project.property("dart-defines") as String
    rawDefines.split(",").forEach { encoded ->
        if (encoded.isNotBlank()) {
            val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            val parts = decoded.split("=", limit = 2)
            if (parts.size == 2) {
                dartEnvironmentVariables[parts[0]] = parts[1]
            }
        }
    }
}

val mapsApiKey: String =
    localProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: dartEnvironmentVariables["MAPS_API_KEY"]?.takeIf { it.isNotBlank() }
        ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: ""

if (mapsApiKey.isEmpty()) {
    logger.warn("[LungsAssistant] WARNING: MAPS_API_KEY is not configured in android/local.properties, --dart-define, or environment variables.")
}

android {
    namespace = "com.example.agent_doctor"
    compileSdk = flutter.compileSdkVersion
    // Gunakan NDK r30+ untuk dukungan penuh 16 KB page size pada Android 15+ (termasuk kompatibilitas libsqlcipher & native libs)
    ndkVersion = "30.0.14904198"

    packaging {
        jniLibs {
            // Wajib false agar native libraries (.so) seperti libsqlcipher.so di-align pada batas 16 KB (16384 bytes) di dalam APK/AAB
            useLegacyPackaging = false
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.agent_doctor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey

        externalNativeBuild {
            cmake {
                arguments("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
                cppFlags("-Wl,-z,max-page-size=16384")
            }
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

flutter {
    source = "../.."
}

// Resolusi otomatis jika ada transitive dependency ke android-database-sqlcipher lama (4 KB page size)
// ke sqlcipher-android >= 4.6.1 yang sudah mendukung 16 KB page size
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "net.zetetic" && requested.name == "android-database-sqlcipher") {
            useTarget("net.zetetic:sqlcipher-android:4.6.1")
            because("Fix Android 15+ 16 KB page size compatibility for libsqlcipher.so")
        }
        if (requested.group == "net.zetetic" && requested.name == "sqlcipher-android") {
            useVersion("4.6.1")
            because("Ensure 16 KB page size aligned libsqlcipher.so")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
