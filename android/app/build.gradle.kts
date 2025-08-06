plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.connectbeat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.connectbeat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debplugins {
            //    id("com.android.application")
            //    id("kotlin-android")
            //    id("dev.flutter.flutter-gradle-plugin")
            //}
            //
            //android {
            //    namespace = "com.example.connectbeat"
            //    compileSdk = 35
            //    ndkVersion = "27.0.12077973"
            //
            //    compileOptions {
            //        sourceCompatibility = JavaVersion.VERSION_11
            //        targetCompatibility = JavaVersion.VERSION_11
            //    }
            //
            //    kotlinOptions {
            //        jvmTarget = JavaVersion.VERSION_11.toString()
            //    }
            //
            //    defaultConfig {
            //        applicationId = "com.example.connectbeat"
            //        minSdk = 21
            //        targetSdk = 35
            //        versionCode = 1
            //        versionName = "1.0"
            //    }
            //
            //    buildTypes {
            //        release {
            //            signingConfig = signingConfigs.getByName("debug")
            //        }
            //    }
            //}
            //
            //flutter {
            //    source = "../.."
            //}
            //
            //dependencies {
            //    implementation("com.google.android.gms:play-services-auth:20.5.0")
            //}ug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
