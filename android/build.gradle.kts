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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Force a minimum desugar_jdk_libs version to satisfy AAR metadata checks (some plugins require >=2.1.4)
subprojects {
    configurations.matching { it.isCanBeResolved }.all {
        resolutionStrategy.force("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}
