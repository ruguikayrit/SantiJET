import 'package:flutter/foundation.dart';

/// ŞantiJET uygulama mağaza bağlantıları.
abstract final class SantijetStoreLinks {
  /// Android paket kimliği (Play Console ile aynı olmalı).
  static const puantajAndroidPackage = 'com.santijet.santijet_puantaj';

  static const puantajPlayStore =
      'https://play.google.com/store/apps/details?id=$puantajAndroidPackage';

  /// Android native market intent.
  static const puantajPlayMarket =
      'market://details?id=$puantajAndroidPackage';

  /// App Store kimliği yayınlanınca buraya yazılır (örn. id1234567890).
  /// Şimdilik arama sayfası açılır.
  static const puantajAppStoreId = '';

  static const puantajAppStoreSearch =
      'https://apps.apple.com/search?term=%C5%9EantiJET%20Puantaj';

  static String get puantajAppStore {
    if (puantajAppStoreId.isEmpty) return puantajAppStoreSearch;
    return 'https://apps.apple.com/app/id$puantajAppStoreId';
  }

  /// Platforma göre indirme / mağaza sayfası.
  static String puantajDownloadUrl() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return puantajAppStore;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return puantajPlayStore;
    }
  }
}
