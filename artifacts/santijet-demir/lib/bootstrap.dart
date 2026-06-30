import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:santijet_demir/app.dart';
import 'package:santijet_demir/core/crash/crash_reporting_service.dart';
import 'package:santijet_demir/data/remote/supabase_service.dart';

const _dataSchemaVersion = 2;

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('accounts'),
    Hive.openBox('projects'),
  ]);

  await _resetPersistedDemoDataIfNeeded();

  // Supabase / Crashlytics uygulamayı bloklamasın — arka planda başlat.
  unawaited(_initSupabaseSafely());
  unawaited(CrashReportingService.instance.initialize());

  runApp(const ProviderScope(child: SantijetDemirApp()));
}

Future<void> _resetPersistedDemoDataIfNeeded() async {
  final settingsBox = Hive.box('settings');
  final storedVersion = settingsBox.get('data_schema_version', defaultValue: 0);
  if (storedVersion is int && storedVersion >= _dataSchemaVersion) return;

  await Hive.box('projects').clear();
  await settingsBox.delete('app_settings');
  await settingsBox.put('data_schema_version', _dataSchemaVersion);
}

Future<void> _initSupabaseSafely() async {
  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('Supabase background init failed: $e\n$stack');
    }
  }
}
