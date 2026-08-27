import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Release signing config ---------------------------------------------
// 本地构建：在 android/key.properties 中填写（已被 .gitignore 忽略）：
//   storePassword=...
//   keyPassword=...
//   keyAlias=...
//   storeFile=my-ks.keystore
// CI 构建：通过环境变量注入（GitHub Actions secrets），与 key.properties 等价：
//   KEYSTORE_STORE_PASSWORD / KEYSTORE_KEY_PASSWORD / KEYSTORE_KEY_ALIAS
// keystore 文件本身（android/app/my-ks.keystore）通过 KEYSTORE_BASE64 secret 解码得到。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val storePasswordFromEnv = System.getenv("KEYSTORE_STORE_PASSWORD")
val keyPasswordFromEnv = System.getenv("KEYSTORE_KEY_PASSWORD")
val keyAliasFromEnv = System.getenv("KEYSTORE_KEY_ALIAS")

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

    signingConfigs {
        create("release") {
            val sp = keystoreProperties["storePassword"] as? String
                ?: storePasswordFromEnv
            storePassword = sp
            keyPassword = keystoreProperties["keyPassword"] as? String
                ?: keyPasswordFromEnv
                ?: sp // 未单独设置 key 密码时回退到 store 密码
            keyAlias = keystoreProperties["keyAlias"] as? String
                ?: keyAliasFromEnv
            storeFile = file(keystoreProperties["storeFile"] as? String ?: "my-ks.keystore")
        }
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
            val releaseSigning = signingConfigs.getByName("release")
            val hasFullCreds = listOf(
                releaseSigning.storePassword,
                releaseSigning.keyPassword,
                releaseSigning.keyAlias
            ).all { !it.isNullOrBlank() } && (releaseSigning.storeFile?.exists() == true)
            val envSigningConfigured = listOf(
                storePasswordFromEnv,
                keyPasswordFromEnv,
                keyAliasFromEnv
            ).any { !it.isNullOrBlank() }

            when {
                // 完整凭据 → 使用正式签名
                hasFullCreds -> signingConfig = releaseSigning

                // 完全没有任何签名配置（本地开发）→ 回退到 debug 签名，保证 `flutter run --release` 可用
                keystoreProperties.isEmpty() && !envSigningConfigured ->
                    signingConfig = signingConfigs.getByName("debug")

                // 部分配置缺失 → 直接报错，避免 CI 静默产出 debug 签名的“生产包”
                else -> throw GradleException(
                    "Release signing is incomplete. Provide android/key.properties " +
                        "or KEYSTORE_STORE_PASSWORD / KEYSTORE_KEY_PASSWORD / KEYSTORE_KEY_ALIAS " +
                        "and ensure android/app/my-ks.keystore exists."
                )
            }
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
