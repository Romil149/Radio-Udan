// Firebase client configuration for Radio Udaan (project: radio-udaan-72232).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for each supported platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for web in Radio Udaan.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase is not configured for macOS in Radio Udaan.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCguBzurEU8WdwT_wzSuahE-DQViCG8vSE',
    appId: '1:508596678027:android:1ed61f37f51077a81b938e',
    messagingSenderId: '508596678027',
    projectId: 'radio-udaan-72232',
    storageBucket: 'radio-udaan-72232.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChfhTPfxKFGGf_7eLsHyD8ng9oSSE5FHI',
    appId: '1:508596678027:ios:a01f237968a65b5b1b938e',
    messagingSenderId: '508596678027',
    projectId: 'radio-udaan-72232',
    storageBucket: 'radio-udaan-72232.firebasestorage.app',
    iosBundleId: 'org.reactjs.native.example.Radio',
  );
}
