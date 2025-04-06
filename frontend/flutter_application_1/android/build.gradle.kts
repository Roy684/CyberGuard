allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define a new build directory relative to the root project
val customBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(customBuildDir)

buildscript {
    // Define versions for dependencies
    val kotlinVersion = "2.1.0"
    val agpVersion = "8.9.0"
    val googleServicesVersion = "4.4.0"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:$agpVersion")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:$googleServicesVersion")

    }
}

// Configure subprojects
subprojects {
    // Set a custom build directory for each subproject
    val subprojectBuildDir: Directory = customBuildDir.dir(project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)

    // Ensure that the app module is evaluated before other subprojects
    project.evaluationDependsOn(":app")
}

// Define a clean task to delete the custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}