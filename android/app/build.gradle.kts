plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.connectbeat"

    // ⚠️ flutter.compileSdkVersion 사용하지 말고 직접 지정해야 Windows에서 오류 안 남
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.connectbeat"

        // image_cropper 5.x 최소 minSdk 21 이상
        minSdk = 23

        // ⚠️ flutter.targetSdkVersion 사용을 피하고 직접 지정
        targetSdk = 34

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 디버그 키로 서명 (테스트용)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ❌ 강제 Kotlin stdlib 제거 — 충돌 원인이었음
    // implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")

    // 카카오 로그인 SDK
    implementation("com.kakao.sdk:v2-user:2.20.6")

    // 앱 호환 라이브러리
    implementation("androidx.appcompat:appcompat:1.6.1")
}
