// Generated from the Firebase Android app configuration for Petunia.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCq-q_u3Ejt61okpgB3hsuXOwmJfdEcg7M',
    appId: '1:226979889183:android:e15807c1b1f3d18b1c552a',
    messagingSenderId: '226979889183',
    projectId: 'petunia-3f069',
    storageBucket: 'petunia-3f069.firebasestorage.app',
  );
}
