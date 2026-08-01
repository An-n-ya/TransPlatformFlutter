allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some plugins (e.g. agora_rtc_engine, iris_method_channel) read
// `rootProject.ext.compileSdkVersion` via safeExtGet() and fall back to
// android-31 when it's not defined. This project also needs 37 because
// permission_handler_android 14.x requires compileSdk >= 37.
extra["compileSdkVersion"] = 37

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
