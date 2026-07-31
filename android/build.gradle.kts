import com.android.build.gradle.BaseExtension
import java.io.FileInputStream
import java.util.Properties

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
    }
}

allprojects {
    repositories {
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

val toolchainProperties = Properties().apply {
    FileInputStream(rootProject.file("toolchain.properties")).use { load(it) }
}
val androidPlatform = toolchainProperties.getProperty("android.platform")
val androidBuildToolsVersion = toolchainProperties.getProperty("android.buildTools")
val androidCmakeVersion = toolchainProperties.getProperty("android.cmake")
val androidNdkVersion = toolchainProperties.getProperty("android.ndk")

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.apply {
            compileSdkVersion("android-$androidPlatform")
            buildToolsVersion = androidBuildToolsVersion
            externalNativeBuild.cmake.version = androidCmakeVersion
            ndkVersion = androidNdkVersion
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
