plugins {
    id("com.android.application")
}

android {
    namespace = "com.dennis.padtest"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.dennis.padtest"
        minSdk = 26
        targetSdk = 36
        versionCode = 5
        versionName = "1.4"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        buildConfig = false
    }
    signingConfigs {
        create("release") {
            storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

// 鍙敤 Android 妗嗘灦 API锛氫笉渚濊禆 AndroidX / Compose锛屼繚璇佺绾垮彲缂栬瘧
dependencies {
}
