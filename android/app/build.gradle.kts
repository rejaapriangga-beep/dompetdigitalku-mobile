import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "id.dompetdigitalku.dompetdigitalku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.dompetdigitalku.dompetdigitalku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Keystore debug TETAP (dikomit ke repo, lihat android/app/keystore/README.md)
        // supaya SEMUA build debug — di CI GitHub Actions maupun lokal —
        // selalu ditandatangani dengan kunci yang SAMA persis. Tanpa ini,
        // tiap run GitHub Actions jalan di VM baru yang bersih dan Android
        // Gradle Plugin otomatis membuat ~/.android/debug.keystore BARU
        // (kunci acak berbeda tiap kali), yang menyebabkan dua masalah:
        // 1. `adb install -r` gagal dengan INSTALL_FAILED_UPDATE_INCOMPATIBLE
        //    setiap kali update APK dari build CI yang berbeda.
        // 2. SHA-1 fingerprint ikut berubah tiap build, jadi Login Google
        //    (yang butuh SHA-1 didaftarkan di Google Cloud Console) selalu
        //    gagal (DEVELOPER_ERROR) karena fingerprint-nya tidak pernah
        //    cocok dengan yang terdaftar.
        create("debug") {
            storeFile = file("keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
