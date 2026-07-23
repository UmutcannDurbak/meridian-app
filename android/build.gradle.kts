// Every plugin subproject (file_picker, image_picker_android, etc.) sets its
// own compileSdk independently of app/build.gradle.kts's compileSdk = 36 —
// that only applies to :app. Some are still published against 34, but
// flutter_plugin_android_lifecycle (pulled in transitively by several of
// them) requires 36+, so the AAR metadata check fails on whichever hasn't
// caught up. Force every Android library module to compile against 36
// instead of waiting on each plugin's own release cadence.
//
// This has to be gradle.beforeProject + a per-project afterEvaluate, and it
// has to be the first thing in this file. Two earlier attempts failed:
//   1. A plain `subprojects { plugins.withId(...) { compileSdk = 36 } }`
//      got silently overwritten — that block runs BEFORE the subproject's
//      own build.gradle finishes, so its own (lower) compileSdk applied
//      afterward and won.
//   2. Wrapping that in `subprojects { afterEvaluate { ... } }`, positioned
//      after the evaluationDependsOn(":app") block below, threw "Cannot run
//      Project.afterEvaluate(Action) when the project is already
//      evaluated" — evaluationDependsOn(":app") forces :app to configure
//      immediately, which (to build its dependency graph) eagerly evaluates
//      the plugin projects it depends on, including file_picker, as a side
//      effect — so by the time that afterEvaluate call ran, file_picker had
//      already finished evaluating.
// gradle.beforeProject fires for every project immediately before THAT
// project's own build.gradle begins — including ones evaluated early as a
// side effect of something else — so registering afterEvaluate inside it
// is always in time, regardless of what forces a given subproject to
// evaluate or when.
gradle.beforeProject {
    afterEvaluate {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
            }
        }
    }
}

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
