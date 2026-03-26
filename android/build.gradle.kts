allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("${rootDir}/../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))

    if (project.name != "app") {
       project.evaluationDependsOn(":app")   }

    project.plugins.withId("com.android.library") {
       configureNamespace(project)
    }
    project.plugins.withId("com.android.application") {
        configureNamespace(project)
    }
}

fun configureNamespace(project: Project) {
    val android = project.extensions.getByName("android")
    try {
        val getNamespaceMethod = android.javaClass.getMethod("getNamespace")
        val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
        
        if (getNamespaceMethod.invoke(android) == null) {
            val group = project.group.toString()
            val namespace = if (group.isNotEmpty()) group else "com.liquid.dialer.${project.name.replace("-", "_")}"
            setNamespaceMethod.invoke(android, namespace)
        }
    } catch (e: Exception) {
        try {
            val field = android.javaClass.getDeclaredField("namespace")
            field.isAccessible = true
            if (field.get(android) == null) {
                val group = project.group.toString()
                val namespace = if (group.isNotEmpty()) group else "com.liquid.dialer.${project.name.replace("-", "_")}"
                field.set(android, namespace)
            }
        } catch (e2: Exception) {
            // Log or ignore if both fail
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
