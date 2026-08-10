import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

/// Hive kutuları — settings, app_state, workspace.
final settingsBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('settingsBoxProvider override edilmedi');
});

final appStateBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('appStateBoxProvider override edilmedi');
});

final workspaceBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('workspaceBoxProvider override edilmedi');
});

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('app_state'),
    Hive.openBox('workspace'),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        appStateBoxProvider.overrideWithValue(boxes[1]),
        workspaceBoxProvider.overrideWithValue(boxes[2]),
      ],
      child: const SantijetAnaApp(),
    ),
  );
}
