import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';

/// Uygulama başlatma — Demir / BFA `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settings = await Hive.openBox('settings');

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(settings),
      ],
      child: const SantijetMuhendisApp(),
    ),
  );
}
