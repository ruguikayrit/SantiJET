import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/demo_seed_provider.dart';
import 'data/providers/favorites_provider.dart';
import 'data/providers/kesif_provider.dart';
import 'data/providers/recent_views_provider.dart';
import 'data/providers/user_analiz_provider.dart';

/// Uygulama başlatma — Demir `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('favorites'),
    Hive.openBox('recent'),
    Hive.openBox('settings'),
    Hive.openBox('user_analizleri'),
    Hive.openBox('kesif_projects'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        favoritesBoxProvider.overrideWithValue(boxes[0]),
        recentBoxProvider.overrideWithValue(boxes[1]),
        settingsBoxProvider.overrideWithValue(boxes[2]),
        userAnalizBoxProvider.overrideWithValue(boxes[3]),
        kesifBoxProvider.overrideWithValue(boxes[4]),
      ],
      child: const _SeedAndRun(child: SantijetBfaApp()),
    ),
  );
}

/// İlk frame’de keşif boşsa demo veri tohumlar.
class _SeedAndRun extends ConsumerStatefulWidget {
  const _SeedAndRun({required this.child});

  final Widget child;

  @override
  ConsumerState<_SeedAndRun> createState() => _SeedAndRunState();
}

class _SeedAndRunState extends ConsumerState<_SeedAndRun> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seedDemoIfEmpty(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
