import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Statik önizlemede /demir yenilemesi 404 olmasın.
  setUrlStrategy(const HashUrlStrategy());
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
