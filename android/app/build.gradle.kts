import java.util.Properties
import java.io.FileInputStream

fun loadFlavorProperties(flavor: String): Properties {
    val propertiesFile = rootProject.file("../config/flavors/$flavor.properties")
    require(propertiesFile.exists()) {
        "Konfigurasi flavor tidak ditemukan: ${propertiesFile.absolutePath}"
    }
    return Properties().apply {
        propertiesFile.inputStream().use(::load)
    }
}

val flavorConfigDirectory = rootProject.file("../config/flavors")
val institutionFlavors = flavorConfigDirectory
    .listFiles { file -> file.isFile && file.extension == "properties" }
    ?.sortedBy { it.nameWithoutExtension }
    ?.associate { file ->
        file.nameWithoutExtension to loadFlavorProperties(file.nameWithoutExtension)
    }
    .orEmpty()

require(institutionFlavors.isNotEmpty()) {
    "Tidak ada konfigurasi flavor di ${flavorConfigDirectory.absolutePath}"
}

fun signingPropertiesFile(flavor: String) =
    rootProject.file("key.$flavor.properties").takeIf { it.exists() }
        ?: rootProject.file("key.properties").takeIf {
            flavor == "khoirunnasyien" && it.exists()
        }

val signingPropertiesByFlavor = institutionFlavors.keys.mapNotNull { flavor ->
    val file = signingPropertiesFile(flavor) ?: return@mapNotNull null
    val properties = Properties().apply {
        load(FileInputStream(file))
    }
    flavor to properties
}.toMap()

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.khoirunnasyien.tahfiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        signingPropertiesByFlavor.forEach { (flavor, properties) ->
            create(flavor) {
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "institution"
    productFlavors {
        institutionFlavors.forEach { (flavor, properties) ->
            create(flavor) {
                dimension = "institution"
                applicationId = properties.getProperty("applicationId")
                resValue(
                    "string",
                    "app_name",
                    properties.getProperty("appName"),
                )
                versionName = System.getenv("APP_VERSION_NAME")
                    ?: properties.getProperty("defaultVersionName")
                versionCode = System.getenv("APP_VERSION_CODE")?.toInt()
                    ?: properties.getProperty("defaultVersionCode").toInt()
                signingConfig = signingConfigs.findByName(flavor)
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

gradle.taskGraph.whenReady {
    institutionFlavors.keys.forEach { flavor ->
        val variantName = flavor.replaceFirstChar { it.uppercase() }
        val releaseRequested = allTasks.any { task ->
            task.project == project &&
                (
                    task.name.equals("bundle${variantName}Release", ignoreCase = true) ||
                        task.name.equals("assemble${variantName}Release", ignoreCase = true)
                )
        }
        require(!releaseRequested || signingPropertiesByFlavor.containsKey(flavor)) {
            "Signing release flavor '$flavor' tidak ditemukan. " +
                "Buat android/key.$flavor.properties atau gunakan pipeline CI flavor tersebut."
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Diperlukan oleh flutter_local_notifications (desugaring Java 8+).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
