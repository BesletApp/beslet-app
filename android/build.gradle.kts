allprojects {
    repositories {
        google()
        mavenCentral()
    }
}



val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// The package:jni native module configures CMake for every ABI in parallel,
// which races on Windows (AGP writes a shared CXX metadata timing file).
// Beslet only ships arm64-v8a release builds, so pin the module to that ABI —
// one configure task, no file-lock race.
subprojects {
    if (name == "jni") {
        afterEvaluate {
            val androidExt = extensions.findByName("android")
            if (androidExt is com.android.build.gradle.LibraryExtension) {
                androidExt.defaultConfig.ndk.abiFilters.clear()
                androidExt.defaultConfig.ndk.abiFilters.add("arm64-v8a")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
