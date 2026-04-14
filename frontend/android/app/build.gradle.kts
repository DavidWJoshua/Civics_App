import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.civicsapp.civic_complaint_system"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { path -> file(path) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        // Application ID — must be unique on the Play Store.
        // Using a proper reverse-domain format (com.yourname.appname)
        applicationId = "com.civicsapp.civic_complaint_system"
        // Minimum SDK: Android 5.0 (API 21) covers 99% of devices
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // versionCode: increment by 1 on every Play Store upload
        versionCode = flutter.versionCode
        // versionName: shown to users on the Play Store listing
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the release key defined above
            signingConfig = signingConfigs.getByName("release")
            // Disable code shrinking and obfuscation to fix the Gradle error
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
