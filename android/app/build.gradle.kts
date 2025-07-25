plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sitemon"
    compileSdk = 35 // Tetap ini atau naikkan ke 34 jika 35 menimbulkan masalah.
    ndkVersion = "29.0.13113456" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sitemon.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // Rekomendasi tetap 34 untuk stabilitas dengan Android 14
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Untuk rilis, gunakan signing config yang benar (bukan debug)
            // Tambahkan proguardFiles jika Anda menggunakan ProGuard/R8
            // minifyEnabled true
            // proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source = "../.."
}