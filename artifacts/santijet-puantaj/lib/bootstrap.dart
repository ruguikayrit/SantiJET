import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/app_data_provider.dart';

/// Uygulama başlatma — Demir / BFA `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('projects'),
    Hive.openBox('personnel'),
    Hive.openBox('attendance'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        projectsBoxProvider.overrideWithValue(boxes[1]),
        personnelBoxProvider.overrideWithValue(boxes[2]),
        attendanceBoxProvider.overrideWithValue(boxes[3]),
      ],
      child: const SantijetPuantajApp(),
    ),
  );
}
