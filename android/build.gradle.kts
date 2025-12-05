allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://jitpack.io") // <--- This enables the streaming library
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.buildDir = File(newBuildDir.asFile, project.name)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}