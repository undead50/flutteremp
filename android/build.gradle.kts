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
// One NDK for the whole build. The `jni` plugin (pulled in by path_provider_android)
// hardcodes `ndkVersion flutter.ndkVersion` in its own build.gradle; override it after its
// script has run so Gradle never needs the (uninstalled) NDK 28.2. Must be registered
// before :app is evaluated below.
subprojects {
    afterEvaluate {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)?.let {
            it.ndkVersion = "27.1.12297006"
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
