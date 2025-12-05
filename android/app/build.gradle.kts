plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.deathnote_streamer"
    compileSdk = 36 // Updated to 36 to satisfy plugin requirements
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.deathnote_streamer"
        minSdk = 24
        targetSdk = 35 // Keeping targetSdk at 35 is fine
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // These MUST be false to avoid the shrinking error
            isMinifyEnabled = false
            isShrinkResources = false 
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // The library required for RTMP streaming
    implementation("com.github.pedroSG94.rtmp-rtsp-stream-client-java:rtplibrary:2.2.4")
}