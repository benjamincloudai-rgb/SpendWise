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

// Workaround: file_picker 11.x only applies the Kotlin Gradle Plugin on
// AGP < 9, relying on AGP 9 built-in Kotlin otherwise. This project uses
// AGP 9.0.1 with android.builtInKotlin=false (Flutter 3.44 legacy mode), and
// Flutter's KGP auto-apply skips file_picker because its build.gradle text
// mentions KGP. Force-apply KGP so its .kt sources compile and
// FilePickerPlugin is emitted for GeneratedPluginRegistrant.
subprojects {
    if (name == "file_picker") {
        if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
            compilerOptions {
                jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
