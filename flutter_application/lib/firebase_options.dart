// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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
    apiKey: 'AIzaSyC_5CMA0uX6Dw8PLvlJs4Y8hzFU1bayZtg',
    appId: '1:1026902486548:web:9a624b1af755490ce60101',
    messagingSenderId: '1026902486548',
    projectId: 'team-charmander-482',
    authDomain: 'team-charmander-482.firebaseapp.com',
    databaseURL: 'https://team-charmander-482-default-rtdb.firebaseio.com',
    storageBucket: 'team-charmander-482.appspot.com',
    measurementId: 'G-HE791BZ4WF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDU0_Gq9LR16XAAgV0K3tsi4FEqc8fQQgs',
    appId: '1:1026902486548:android:7f9994fa30fe0655e60101',
    messagingSenderId: '1026902486548',
    projectId: 'team-charmander-482',
    databaseURL: 'https://team-charmander-482-default-rtdb.firebaseio.com',
    storageBucket: 'team-charmander-482.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDgnKfMYBS9NgaJAeJigbzJwVFk67zKjxM',
    appId: '1:1026902486548:ios:537cc5c5d9fce668e60101',
    messagingSenderId: '1026902486548',
    projectId: 'team-charmander-482',
    databaseURL: 'https://team-charmander-482-default-rtdb.firebaseio.com',
    storageBucket: 'team-charmander-482.appspot.com',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDgnKfMYBS9NgaJAeJigbzJwVFk67zKjxM',
    appId: '1:1026902486548:ios:843c79863295abade60101',
    messagingSenderId: '1026902486548',
    projectId: 'team-charmander-482',
    databaseURL: 'https://team-charmander-482-default-rtdb.firebaseio.com',
    storageBucket: 'team-charmander-482.appspot.com',
    iosBundleId: 'com.example.flutterApplication.RunnerTests',
  );
}
