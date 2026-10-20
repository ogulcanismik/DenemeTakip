import java.io.File
import java.io.FileInputStream
import java.security.KeyStore
import java.security.MessageDigest
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play Console upload certificate for com.appbyOI.denemeTakip.
val expectedUploadSha1 = "69:33:DD:E8:B0:D5:9A:25:3F:2B:1F:48:E3:ED:E3:78:6D:70:87:2A"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.appbyOI.denemeTakip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.appbyOI.denemeTakip"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed Play builds need android/key.properties; otherwise use debug so local
            // checkouts without a keystore still configure/build. bundleRelease still
            // refuses that fallback and checks the upload certificate below.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

tasks.configureEach {
    if (name != "bundleRelease" && name != "signReleaseBundle") return@configureEach
    doFirst {
        verifyPlayUploadCertificate()
    }
}

fun verifyPlayUploadCertificate() {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Play App Bundle requires android/key.properties. " +
                "The upload certificate SHA-1 must be $expectedUploadSha1.",
        )
    }

    val storePath = keystoreProperties.getProperty("storeFile")
        ?: throw GradleException("key.properties is missing storeFile.")
    val storePassword = keystoreProperties.getProperty("storePassword")
        ?: throw GradleException("key.properties is missing storePassword.")
    val alias = keystoreProperties.getProperty("keyAlias")
        ?: throw GradleException("key.properties is missing keyAlias.")
    val storeFile = file(storePath)
    if (!storeFile.isFile) {
        throw GradleException("Upload keystore not found at ${storeFile.path}.")
    }

    val store = loadKeyStore(storeFile, storePassword.toCharArray())
    val cert = store.getCertificate(alias)
        ?: throw GradleException("Keystore has no certificate for alias $alias.")
    val actual = sha1Fingerprint(cert.encoded)
    if (!actual.equals(expectedUploadSha1, ignoreCase = true)) {
        throw GradleException(
            "Upload certificate SHA-1 is $actual, required $expectedUploadSha1.",
        )
    }
}

fun loadKeyStore(storeFile: File, password: CharArray): KeyStore {
    var lastError: Exception? = null
    for (type in listOf("PKCS12", "JKS")) {
        try {
            val store = KeyStore.getInstance(type)
            FileInputStream(storeFile).use { store.load(it, password) }
            return store
        } catch (error: Exception) {
            lastError = error
        }
    }
    throw GradleException(
        "Could not read the upload keystore: ${lastError?.message ?: "unknown error"}",
    )
}

fun sha1Fingerprint(encodedCertificate: ByteArray): String {
    val digest = MessageDigest.getInstance("SHA-1").digest(encodedCertificate)
    return digest.joinToString(":") { "%02X".format(it) }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
}
