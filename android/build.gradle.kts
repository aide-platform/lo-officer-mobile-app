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

// Do not use evaluationDependsOn(":app") with AGP 9 / Gradle 9 —
// it evaluates :app early and breaks afterEvaluate.

// Force plugin modules (e.g. file_picker @ compileSdk 34) up to 36+.
apply(from = "fix_compile_sdk.gradle")

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
