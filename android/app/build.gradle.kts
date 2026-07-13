import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun loadFlavorProperties(flavor: String): Properties {
    val propertiesFile = rootProject.file("../config/flavors/$flavor.properties")
    require(propertiesFile.exists()) {
        "Konfigurasi flavor tidak ditemukan: ${propertiesFile.absolutePath}"
    }
    return Properties().apply {
        propertiesFile.inputStream().use(::load)
    }
}

val khoirunnasyienFlavor = loadFlavorProperties("khoirunnasyien")

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
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
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
        create("khoirunnasyien") {
            dimension = "institution"
            applicationId = khoirunnasyienFlavor.getProperty("applicationId")
            resValue(
                "string",
                "app_name",
                khoirunnasyienFlavor.getProperty("appName"),
            )
            versionName = System.getenv("APP_VERSION_NAME")
                ?: khoirunnasyienFlavor.getProperty("defaultVersionName")
            versionCode = System.getenv("APP_VERSION_CODE")?.toInt()
                ?: khoirunnasyienFlavor.getProperty("defaultVersionCode").toInt()
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
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
