import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/hive_boxes.dart';
import 'data/records_store.dart';

/// Uygulama başlatma — Hive kutuları `tahvil_` önekli.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(TahvilHive.nativeSubdir);
  final settings = await Hive.openBox(TahvilHive.settings);
  final records = await Hive.openBox(TahvilHive.records);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(settings),
        recordsBoxProvider.overrideWithValue(records),
      ],
      child: const SantijetTahvilApp(),
    ),
  );
}
