import 'package:firebase_core/firebase_core.dart';

/// Placeholder Firebase options — production'da `flutterfire configure` ile değiştirin.
/// Detay: docs/FIREBASE_SETUP.md
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:android:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'santijet-demir-placeholder',
    storageBucket: 'santijet-demir-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:ios:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'santijet-demir-placeholder',
    storageBucket: 'santijet-demir-placeholder.appspot.com',
    iosBundleId: 'com.santijet.santijetDemir',
  );

  static FirebaseOptions get currentPlatform {
    // Web/desktop test ortamları için Android fallback kullan.
    return android;
  }
}
