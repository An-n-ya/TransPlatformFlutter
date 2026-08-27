plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.trans_platform"
    // permission_handler_android 14.x requires compileSdk >= 37
    // (flutter.compileSdkVersion default is 36).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.trans_platform"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---- Flavors: prod / dev -------------------------------------------
    // 每个 flavor 需要配合 --dart-define=appFlavor=<flavor> 使用，
    // 使 Dart 侧 (lib/config/env.dart) 能读取到当前构建的环境。
    //
    //   flutter run   --flavor dev
    //   flutter build apk --release --flavor prod --dart-define=appFlavor=prod
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            // 与生产包区分开，可同时安装在同一台设备上
            applicationIdSuffix = ".dev"
            // 应用名见 src/dev/res/values/strings.xml（AGP 9 不允许在 flavor 里 resValue）
        }
        create("prod") {
            dimension = "env"
            // 生产包只保留 arm64-v8a，减小安装包体积
            ndk {
                abiFilters.clear()
                abiFilters.addAll(listOf("arm64-v8a"))
            }
        }
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
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
