import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/providers/favorites_provider.dart';
import 'data/providers/recent_views_provider.dart';

/// Uygulama başlatma — Demir `bootstrap()` deseniyle hizalı.
///
/// Hive yerel kalıcılığı başlatılır (favoriler, son görüntülenenler, ayarlar,
/// özel analizler/keşif Faz 9/12'de eklenecektir).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('favorites'),
    Hive.openBox('recent'),
    Hive.openBox('settings'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        favoritesBoxProvider.overrideWithValue(boxes[0]),
        recentBoxProvider.overrideWithValue(boxes[1]),
      ],
      child: const SantijetBfaApp(),
    ),
  );
}
