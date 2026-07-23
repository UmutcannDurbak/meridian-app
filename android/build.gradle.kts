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

// Every plugin subproject (file_picker, image_picker_android, etc.) sets its
// own compileSdk independently of app/build.gradle.kts's compileSdk = 36 —
// that setting only applies to :app. Some of these plugins are still
// published against compileSdk 34, but flutter_plugin_android_lifecycle
// (pulled in transitively by several of them) requires 36+, so the AAR
// metadata check fails on whichever plugin hasn't caught up yet. Rather than
// wait on each plugin's own release cadence, force every Android library
// module in the build to compile against the same SDK :app already does.
//
// Must be wrapped in afterEvaluate: subprojects {} content configures each
// subproject BEFORE that subproject's own build.gradle finishes running, so
// without this, the plugin's own (lower) compileSdk was being applied AFTER
// ours and silently winning — same failure, same plugin, even with this
// block present but unwrapped.
subprojects {
    afterEvaluate {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
