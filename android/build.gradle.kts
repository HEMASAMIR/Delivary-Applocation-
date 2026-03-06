buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.6.0") // حدثنا هنا كمان
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0") // وهنا
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }  
}

// تحديث الطريقة القديمة لتعريف مسار الـ Build
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    val newBuildDir = file("${rootProject.layout.buildDirectory.get()}/${project.name}")
    project.layout.buildDirectory.set(newBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}