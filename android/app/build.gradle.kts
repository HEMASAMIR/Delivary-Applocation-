plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.myapp"
    
    // الحل الأول: أبقينا فقط النسخة الأحدث وحذفنا المكرر
    ndkVersion = "27.0.12077973" 
    
    compileSdk = 36 // نصيحة: استقر على 35 حالياً لأن 36 ما زالت تجريبية لبعض الإضافات

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = flutter.minSdkVersion // يفضل تحديدها بـ 21 لضمان عمل الـ Desugaring بشكل سليم
        targetSdk = 36
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    compileOptions {
        // الحل الثاني: تفعيل المكتبة يتطلب إضافة dependency بالأسفل (انظر آخر الكود)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// الحل الثالث: إضافة المكتبة المفقودة التي سببت خطأ l8DexDesugarLibDebug
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.activity:activity:1.9.3")
    }
}
