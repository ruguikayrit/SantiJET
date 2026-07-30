import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/app_data_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('projects'),
    Hive.openBox('pour_plans'),
    Hive.openBox('pour_records'),
    Hive.openBox('orders'),
    Hive.openBox('quality_samples'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        projectsBoxProvider.overrideWithValue(boxes[1]),
        pourPlansBoxProvider.overrideWithValue(boxes[2]),
        pourRecordsBoxProvider.overrideWithValue(boxes[3]),
        ordersBoxProvider.overrideWithValue(boxes[4]),
        qualityBoxProvider.overrideWithValue(boxes[5]),
      ],
      child: const _SeedAndRun(child: SantijetBetonR1App()),
    ),
  );
}

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
        plans: ref.read(pourPlansProvider.notifier),
        pours: ref.read(pourRecordsProvider.notifier),
        orders: ref.read(ordersProvider.notifier),
        quality: ref.read(qualityProvider.notifier),
        active: ref.read(activeProjectIdProvider.notifier),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
