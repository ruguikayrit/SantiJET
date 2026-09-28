import 'package:flutter/material.dart';

import 'app.dart';
import 'url_strategy_stub.dart' if (dart.library.html) 'url_strategy_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  useHashUrlStrategy();
  ErrorWidget.builder = (details) {
    return ColoredBox(
      color: const Color(0xFF05070A),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
        ),
      ),
    );
  };
  runApp(const SantijetProApp());
}
