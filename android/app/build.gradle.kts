import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val resolvedApplicationId =
    System.getenv("ANDROID_APPLICATION_ID")
        ?: project.findProperty("applicationId") as String?
        ?: "pw.rabit.astralng"

val toolchainProperties = Properties().apply {
    FileInputStream(rootProject.file("toolchain.properties")).use { load(it) }
}

android {
    namespace = "pw.rabit.astralng"
    compileSdk = toolchainProperties.getProperty("android.compileSdk").toInt()
    toolchainProperties.getProperty("android.compileSdkMinor").toInt().let { minor ->
        if (minor > 0) compileSdkMinor = minor
    }
    buildToolsVersion = toolchainProperties.getProperty("android.buildTools")
    ndkVersion = toolchainProperties.getProperty("android.ndk")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // 启用 core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
     // 添加 buildFeatures 配置
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = resolvedApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = toolchainProperties.getProperty("android.targetSdk").toInt()
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 添加对多窗口模式的配置
        manifestPlaceholders["isResizeableActivity"] = "true"
    }

  signingConfigs {
      create("release") {
          keyAlias = keystoreProperties["keyAlias"] as? String
          keyPassword = keystoreProperties["keyPassword"] as? String
          storeFile = keystoreProperties["storeFile"]?.let { file(it) }
          storePassword = keystoreProperties["storePassword"] as? String
      }
  }

    buildTypes {
        release {
          signingConfig = signingConfigs.getByName("release")
            //   signingConfig = signingConfigs.getByName("debug")

        }
    }

}

// 添加 dependencies 块
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 添加对窗口模式的支持
    implementation("androidx.window:window:1.2.0-beta05")
    implementation("androidx.window:window-java:1.2.0-beta05")

}

flutter {
    source = "../.."
}
