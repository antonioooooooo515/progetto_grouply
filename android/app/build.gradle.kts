// android/app/build.gradle.kts

@Suppress("DSL_SCOPE_VIOLATION")
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // Plugin necessario per Firebase
}

android {
    namespace = "com.example.progetto_grouply"   // ⚠️ Usa il tuo package
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.progetto_grouply"  // ⚠️ Deve combaciare con google-services.json
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")

    // Firebase BOM → allinea le versioni automaticamente
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))

    // Moduli Firebase
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-analytics")

    // Multidex (necessario quando ci sono molte dipendenze)
    implementation("androidx.multidex:multidex:2.0.1")
}
