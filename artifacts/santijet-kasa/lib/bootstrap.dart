import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/hareketler_store.dart';
import 'data/hive_boxes.dart';
import 'data/settings_store.dart';

/// Uygulama başlatma — Hive kutuları `kasa_` önekli.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(KasaHive.nativeSubdir);
  final settings = await Hive.openBox(KasaHive.settings);
  final hareketler = await Hive.openBox(KasaHive.hareketler);
  final santiyeler = await Hive.openBox(KasaHive.santiyeler);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(settings),
        hareketlerBoxProvider.overrideWithValue(hareketler),
        santiyelerBoxProvider.overrideWithValue(santiyeler),
      ],
      child: const SantijetKasaApp(),
    ),
  );
}
