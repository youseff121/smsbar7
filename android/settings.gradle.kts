pluginManagement {
    val flutterSdkPath = providers.gradleProperty("flutter.sdk").get()
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("com.android.application") version "9.1.1" apply false
}

include(":app")
