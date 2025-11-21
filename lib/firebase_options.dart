import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'La piattaforma corrente non è configurata in firebase_options.dart',
        );
    }
  }

  // 🌐 WEB
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyABtE542Tjl37l-q4u65hWELHFFDAN14m8",
    appId: "1:145866469912:web:ce856118279277100ec96d",
    messagingSenderId: "145866469912",
    projectId: "grouply-team-manager",
    authDomain: "grouply-team-manager.firebaseapp.com",
    storageBucket: "grouply-team-manager.firebasestorage.app",
    measurementId: "G-J3SQB9VH8X",
  );

  // 🤖 ANDROID
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyC_hx9nUcxskgSvZ_a9ZpOSL3NMNVdpKKY",
    appId: "1:145866469912:android:31e7b6ae035508040ec96d",
    messagingSenderId: "145866469912",
    projectId: "grouply-team-manager",
    storageBucket: "grouply-team-manager.firebasestorage.app",
  );

  // 🍎 iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCS5ec27kCeooGWJzC1nkgj0AEwEh5keyI",
    appId: "1:145866469912:ios:fef7553c47d805ae0ec96d",
    messagingSenderId: "145866469912",
    projectId: "grouply-team-manager",
    storageBucket: "grouply-team-manager.firebasestorage.app",
    iosClientId:
    "145866469912-hb152olqqv3532f71fbl9mn413btddj6.apps.googleusercontent.com",
    iosBundleId: "com.example.progettoGrouply",
  );
}
