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

// Plugins such as file_picker may ship with compileSdk 34 while
// flutter_plugin_android_lifecycle requires 36+. Align all Android modules.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        fun invokeSetter(methodName: String, value: Any): Boolean {
            return try {
                val method = androidExt.javaClass.methods.firstOrNull { m ->
                    m.name == methodName && m.parameterCount == 1
                } ?: return false
                method.invoke(androidExt, value)
                true
            } catch (_: Exception) {
                false
            }
        }
        // Prefer AGP 8+ `compileSdk = 36`, fall back to legacy compileSdkVersion.
        if (!invokeSetter("setCompileSdk", 36)) {
            invokeSetter("setCompileSdkVersion", 36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
