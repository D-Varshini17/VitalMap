import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCezEGksVBLrF75hapcj7DjDPKMsw48S80',
    appId: '1:200190188175:web:ea2b409277fdf126c2aefa',
    messagingSenderId: '200190188175',
    projectId: 'vitalmap-77d53',
    authDomain: 'vitalmap-77d53.firebaseapp.com',
    storageBucket: 'vitalmap-77d53.firebasestorage.app',
    measurementId: 'G-4N16Q0PB4R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmhIOL9YWIqDBoaJfZNNyHsbmW2h_o6Qo',
    appId: '1:200190188175:android:62d452cbd4aa3a29c2aefa',
    messagingSenderId: '200190188175',
    projectId: 'vitalmap-77d53',
    storageBucket: 'vitalmap-77d53.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6Qs2N_ZBFftHMg28GKEScXwU2ksCO64M',
    appId: '1:200190188175:ios:d8632a2cd4de0d71c2aefa',
    messagingSenderId: '200190188175',
    projectId: 'vitalmap-77d53',
    storageBucket: 'vitalmap-77d53.firebasestorage.app',
    iosBundleId: 'com.example.vitalmap',
  );
}
