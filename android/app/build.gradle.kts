plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            android {
                defaultConfig {
                    ndk {
                        abiFilters += "arm64-v8a"
                    }
                }
            }
        }
    }
}

android {
    namespace = "com.amu.beslet_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.amu.beslet_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }



    signingConfigs {
        create("release") {
            keyAlias = "beslet"
            keyPassword = "Beslet2024!"
            storeFile = file("../../beslet-key.jks")
            storePassword = "Beslet2024!"
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
