import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/bootstrap.dart';
import 'package:santijet_demir/core/crash/crash_reporting_service.dart';
import 'dart:async';

Future<void> main() async {
  runZonedGuarded(() async {
    try {
      await bootstrap();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Bootstrap failed: $error\n$stack');
      }
      runApp(BootstrapErrorApp(error: error.toString()));
    }
  }, (error, stack) {
    CrashReportingService.instance.recordError(error, stack, fatal: true);
  });
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF05070A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sayfayı yenileyin veya Safari önbelleğini temizleyin.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
