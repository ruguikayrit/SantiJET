import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/firebase_options.dart';

/// Uygulama geneli hata yakalama — Firebase Crashlytics + yerel Hive log.
class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  static const _logBoxName = 'crash_logs';
  static const _maxLocalLogs = 50;

  bool _firebaseEnabled = false;
  Box? _logBox;

  bool get isFirebaseEnabled => _firebaseEnabled;

  Future<void> initialize() async {
    _logBox = await Hive.openBox(_logBoxName);

    await _tryInitializeFirebase();

    FlutterError.onError = (details) {
      _recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> _tryInitializeFirebase() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _firebaseEnabled = true;
      developer.log('Firebase Crashlytics initialized', name: 'CrashReporting');
    } catch (e, stack) {
      _firebaseEnabled = false;
      developer.log(
        'Firebase unavailable — local crash logging active: $e',
        name: 'CrashReporting',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    recordError(
      details.exception,
      details.stack,
      fatal: true,
      reason: details.context?.toString(),
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    developer.log(
      reason ?? error.toString(),
      name: 'CrashReporting',
      error: error,
      stackTrace: stack,
    );

    await _persistLocalLog(error, stack, fatal: fatal, reason: reason);

    if (_firebaseEnabled) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason,
      );
    }
  }

  Future<void> log(String message) async {
    developer.log(message, name: 'CrashReporting');
    if (_firebaseEnabled) {
      await FirebaseCrashlytics.instance.log(message);
    }
  }

  Future<void> _persistLocalLog(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {
    final box = _logBox;
    if (box == null) return;

    final logs = List<Map>.from(box.get('entries', defaultValue: <Map>[]) as List);
    logs.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stack': stack?.toString(),
      'fatal': fatal,
      'reason': reason,
    });
    if (logs.length > _maxLocalLogs) {
      logs.removeRange(_maxLocalLogs, logs.length);
    }
    await box.put('entries', logs);
  }

  List<Map> getLocalLogs() {
    final box = _logBox;
    if (box == null) return [];
    return List<Map>.from(box.get('entries', defaultValue: <Map>[]) as List);
  }
}

/// Bootstrap için zone wrapper — yakalanmamış async hataları yakalar.
Future<void> runWithCrashReporting(Future<void> Function() appRunner) async {
  await runZonedGuarded(
    appRunner,
    (error, stack) {
      CrashReportingService.instance.recordError(error, stack, fatal: true);
    },
  );
}
