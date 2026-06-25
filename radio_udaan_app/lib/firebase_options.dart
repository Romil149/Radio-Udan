// Firebase client configuration for Radio Udaan (project: radio-udan-2412a).
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
    apiKey: 'AIzaSyC4Dp_WOnvLLjjebn0FUKskJ5aPm0_6kXQ',
    appId: '1:860433527358:android:b4f6cd16e5a950513b976f',
    messagingSenderId: '860433527358',
    projectId: 'radio-udan-2412a',
    storageBucket: 'radio-udan-2412a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAaEF-avXWuNGwJzPUtm604HJdgAPqboic',
    appId: '1:860433527358:ios:dd042cfa744981f23b976f',
    messagingSenderId: '860433527358',
    projectId: 'radio-udan-2412a',
    storageBucket: 'radio-udan-2412a.firebasestorage.app',
    iosBundleId: 'org.reactjs.native.example.Radio',
  );
}
