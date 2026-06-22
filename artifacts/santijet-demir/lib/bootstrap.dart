import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:santijet_demir/app.dart';
import 'package:santijet_demir/core/crash/crash_reporting_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('accounts');
  await Hive.openBox('projects');

  await CrashReportingService.instance.initialize();

  await runWithCrashReporting(() async {
    runApp(const ProviderScope(child: SantijetDemirApp()));
  });
}