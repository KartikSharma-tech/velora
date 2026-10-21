import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties().apply {
    if (releaseKeyPropertiesFile.exists()) {
        releaseKeyPropertiesFile.inputStream().use(::load)
    }
}

android {
    namespace = "com.example.velora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.velora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isDebuggable = false
            if (releaseKeyPropertiesFile.exists()) {
                signingConfigs.create("release") {
                    keyAlias = releaseKeyProperties.getProperty("keyAlias")
                        ?: throw GradleException("keyAlias is missing from android/key.properties")
                    keyPassword = releaseKeyProperties.getProperty("keyPassword")
                        ?: throw GradleException("keyPassword is missing from android/key.properties")
                    storeFile = rootProject.file(
                        releaseKeyProperties.getProperty("storeFile")
                            ?: throw GradleException("storeFile is missing from android/key.properties"),
                    )
                    storePassword = releaseKeyProperties.getProperty("storePassword")
                        ?: throw GradleException("storePassword is missing from android/key.properties")
                }
                signingConfig = signingConfigs.getByName("release")
            } else if (providers.gradleProperty("allowDebugReleaseSigning").orNull == "true") {
                // For local sideload testing only. Never distribute this APK.
                signingConfig = signingConfigs.getByName("debug")
            } else {
                // Produce an unsigned artifact until a private release key is configured.
                signingConfig = null
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
