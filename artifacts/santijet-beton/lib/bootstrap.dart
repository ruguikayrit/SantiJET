import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/app_data_provider.dart';

/// Uygulama başlatma — Demir / Puantaj `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('projects'),
    Hive.openBox('discovery'),
    Hive.openBox('pours'),
    Hive.openBox('orders'),
    Hive.openBox('variance'),
    Hive.openBox('quality'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        projectsBoxProvider.overrideWithValue(boxes[1]),
        discoveryBoxProvider.overrideWithValue(boxes[2]),
        poursBoxProvider.overrideWithValue(boxes[3]),
        ordersBoxProvider.overrideWithValue(boxes[4]),
        varianceBoxProvider.overrideWithValue(boxes[5]),
        qualityBoxProvider.overrideWithValue(boxes[6]),
      ],
      child: const _SeedAndRun(child: SantijetBetonApp()),
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
      seedDemoIfEmpty(
        projects: ref.read(projectsProvider.notifier),
        discovery: ref.read(discoveryProvider.notifier),
        pours: ref.read(poursProvider.notifier),
        orders: ref.read(ordersProvider.notifier),
        variance: ref.read(varianceProvider.notifier),
        active: ref.read(activeProjectIdProvider.notifier),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
