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
// agora_rtc_engine 6.6.4 compila su módulo Android contra android-31, y sus
// dependencias de AndroidX piden 34 o más: el build falla en
// checkDebugAarMetadata. Se fuerza el compileSdk de los plugins al del app.
// Va antes del evaluationDependsOn: después, los plugins ya están evaluados
// y afterEvaluate no se puede registrar.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.compileSdk = 36
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
