import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing keys come from key.properties locally, from env vars on CI.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.hacan359.tonkatsubox"
    // permission_handler 13 compiles against 37; Flutter 3.50 defaults to 36.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.hacan359.tonkatsubox"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Env vars on CI, key.properties locally.
            storeFile = file(
                System.getenv("KEYSTORE_PATH")
                    ?: keystoreProperties.getProperty("storeFile", "")
            )
            storePassword =
                System.getenv("KEYSTORE_PASSWORD")
                    ?: keystoreProperties.getProperty("storePassword", "")
            keyAlias =
                System.getenv("KEY_ALIAS")
                    ?: keystoreProperties.getProperty("keyAlias", "")
            keyPassword =
                System.getenv("KEYSTORE_PASSWORD")
                    ?: keystoreProperties.getProperty("keyPassword", "")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
