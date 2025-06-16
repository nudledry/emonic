import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties") // Gunakan kutip ganda untuk string
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Fungsi untuk membaca properti dari local.properties
fun getFlutterVersionCode(): Int {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localProperties.load(FileInputStream(localPropertiesFile))
        return localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
    }
    return 1 // Default jika file tidak ada atau properti tidak ditemukan
}

fun getFlutterVersionName(): String {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localProperties.load(FileInputStream(localPropertiesFile))
        return localProperties.getProperty("flutter.versionName") ?: "1.0"
    }
    return "1.0" // Default jika file tidak ada atau properti tidak ditemukan
}

android {
    namespace = "com.example.emonic"
    compileSdk = 35 // Pastikan SDK versi 35 sudah terinstall atau sesuaikan dengan versi yang ada
    ndkVersion = "27.0.12077973" // Pastikan NDK ini terinstall

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.emonic"
        minSdk = 23
        targetSdk = 34
        versionCode = getFlutterVersionCode() // Panggil fungsi untuk mendapatkan versionCode
        versionName = getFlutterVersionName() // Panggil fungsi untuk mendapatkan versionName
    }

    signingConfigs {
        create("release") { // Gunakan create untuk mendefinisikan signing config
            if (keystorePropertiesFile.exists()) {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release") // Terapkan konfigurasi signing
            isMinifyEnabled = true // Gunakan isMinifyEnabled
            isShrinkResources = true // Gunakan isShrinkResources
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    // Tambahkan dependensi Firebase lainnya jika diperlukan, misalnya:
    // implementation("com.google.firebase:firebase-auth-ktx")
    // implementation("com.google.firebase:firebase-firestore-ktx")
}