plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.healthy_eating_flutter"
    compileSdk = 36  // ✅ Обновлено с 33 на 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11  // ✅ Было VERSION_8
        targetCompatibility = JavaVersion.VERSION_11  // ✅ Было VERSION_8
        // ✅ Включаем desugaring для Java 8 функций
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"  // ✅ Было "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.healthy_eating_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // ✅ И здесь тоже на 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

repositories {
    google()
    mavenCentral() // добавлено, иначе kotlin stdlib может не скачаться
}

dependencies {
    // Обязательно: подключаем Kotlin stdlib, чтобы плагины (shared_preferences и др.) компилировались
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22")
    
    // ✅ Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}



