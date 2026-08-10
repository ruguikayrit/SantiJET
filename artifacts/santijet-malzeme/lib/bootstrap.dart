import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/app_data_provider.dart';
import 'data/providers/demo_seed_provider.dart';

/// Uygulama başlatma — Beton / Puantaj `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('projects'),
    Hive.openBox('kesif'),
    Hive.openBox('requests'),
    Hive.openBox('quotes'),
    Hive.openBox('deliveries'),
    Hive.openBox('library'),
    Hive.openBox('unit_consumptions'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        projectsBoxProvider.overrideWithValue(boxes[1]),
        kesifBoxProvider.overrideWithValue(boxes[2]),
        requestsBoxProvider.overrideWithValue(boxes[3]),
        quotesBoxProvider.overrideWithValue(boxes[4]),
        deliveriesBoxProvider.overrideWithValue(boxes[5]),
        libraryBoxProvider.overrideWithValue(boxes[6]),
        unitConsumptionsBoxProvider.overrideWithValue(boxes[7]),
      ],
      child: const _SeedAndRun(child: SantijetMalzemeApp()),
    ),
  );
}

/// İlk frame’de boşsa demo veri tohumlar.
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
