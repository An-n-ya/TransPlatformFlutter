allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some plugins read `rootProject.ext.compileSdkVersion` via safeExtGet() and
// fall back to android-31 when it's not defined. Keep 37 to be compatible with
// newer plugin releases (e.g. flutter_secure_storage, image_picker).
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
