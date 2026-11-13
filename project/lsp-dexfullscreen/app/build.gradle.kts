plugins {
    id("com.android.application")
}

android {
    namespace = "com.dennis.dexfs"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.dennis.dexfs"
        minSdk = 32
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    compileOnly("de.robv.android.xposed:api:82")
    compileOnly("de.robv.android.xposed:api:82:sources")
}
