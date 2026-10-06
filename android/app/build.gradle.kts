import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// tarus: release yalnız tarus'a özel anahtarla (git dışı android/key.properties)
// imzalanır. Saber'in depoda açık duran yedek anahtarı (fallback-key.jks) kaldırıldı:
// onunla imzalanan APK için herkes `tr.tarus.not` güncellemesi üretebilirdi.
// Debug derlemeler Android'in yerel debug anahtarını kullanır. Bkz. TARUS_NOT.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseImzasiVar = keystorePropertiesFile.exists()
if (releaseImzasiVar) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

gradle.taskGraph.whenReady {
    if (!releaseImzasiVar && allTasks.any { it.name.contains("Release") }) {
        throw GradleException(
            "android/key.properties yok: release APK tarus imza anahtarı olmadan derlenmez (TARUS_NOT.md → İmza anahtarı)."
        )
    }
}

// tarus: Play versionCode = tarus buildNumber (lib/data/version.dart, 1.1.3 → 101030)
// + 2_000_000. Paket tr.tarus.not Saber sürüm şemasıyla 1.36.1 (136010; ABI'ye
// bölünmüş APK'da ×10+ABI → 1360103'e kadar) kodlarını taşıdı; tarus şeması
// 1.0.0'da 100000'e indi. Kaydırma, Play'e giden her kodun (AAB 2101030…,
// bölünmüş APK 21010302…) eskilerin hepsinden büyük ve monoton artan kalmasını
// sağlar. Değiştirmeyin: Play'e yüklenen kod bir daha küçültülemez.
val playSurumKaydirma = 2_000_000

android {
    namespace = "tr.tarus.not"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "tr.tarus.not"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Play şartı (31 Ağustos 2026'dan): yeni uygulama ve güncellemeler
        // Android 16 / API 36 hedeflemeli (developer.android.com/google/play/requirements/target-sdk).
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        versionCode = flutter.versionCode + playSurumKaydirma
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseImzasiVar) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            if (releaseImzasiVar) signingConfig = signingConfigs.getByName("release")
        }
    }

    packaging {
        jniLibs.pickFirsts.add("lib/*/libc++_shared.so")
    }
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
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.10")
    implementation("com.google.android.material:material:1.14.0")
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}
